import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blowfish_ecb/blowfish_ecb.dart';
import 'package:dartcarwings/src/carwings_vehicle.dart';
import 'package:http/http.dart' as http;

enum CarwingsRegion { World, USA, Europe, Canada, Australia, Japan }

class CarwingsSession {
  final String baseUrl = 'https://gdcportalgw.its-mo.com/api_v230317_NE/gdc/';

  // Result of the call to InitialApp.php, which appears to
  // always be the same.  It'll probably break at some point but
  // for now... skip it
  final String blowfishKey = 'uyI5Dj9g8VCOFDnBRUbr3g';

  // Extracted from the NissanConnect EV app
  final String initialAppStrings = '9s5rfKVuMrT03RtzajWNcA';

  bool debug;
  List<String> debugLog = <String>[];

  // If this is set it will override the time zone returned from Carwings API
  String? timeZoneOverride;

  var username;
  var password;
  late CarwingsRegion region;
  var userAgent =
      'Dalvik/2.1.0 (Linux; U; Android 5.1.1; Android SDK built for x86 Build/LMY48X)';
  bool loggedIn = false;
  var gdcUserId;
  var timeZoneProvided;
  var language;
  var dcmId;
  int modelYear = 0;

  late CarwingsVehicle vehicle;
  late List<CarwingsVehicle> vehicles;

  CarwingsSession({this.debug = false, this.timeZoneOverride});

  Future<dynamic> requestWithRetry(String endpoint, Map params) async {
    dynamic response = await request(endpoint, params);

    var status = response['status'];

    if (status != null && status >= 400) {
      _print('Carwings API; logging in and trying request again: $response');

      await login(username: username, password: password);

      response = await request(endpoint, params);
    }
    return response;
  }

  Future<dynamic> request(String endpoint, Map params) async {
    params['initial_app_str'] = initialAppStrings;

    _print('Invoking Carwings API: $endpoint');
    _print('Params: $params');

    http.Response response = await http.post(Uri.parse('${baseUrl}${endpoint}'),
        headers: {
          'User-Agent': userAgent,
        },
        body: params);

    dynamic jsonData = json.decode(response.body);

    _print('Result: $jsonData');

    return jsonData;
  }

  Future<CarwingsVehicle> login(
      {required String username,
      required String password,
      CarwingsRegion region = CarwingsRegion.Europe,
      String? userAgent}) async {
    this.username = username;
    this.password = password;
    this.region = region;

    if (userAgent != null) {
      this.userAgent = userAgent;
    }

    loggedIn = false;

    var response = await request('InitialApp_v2.php',
        {'RegionCode': _getRegionName(region), 'lg': 'en-US'});

    final blowfish =
        BlowfishECB(Uint8List.fromList(utf8.encode(response['baseprm'])));

    var padPKCS5 = (List<int> input) {
      final inputLength = input.length;
      final paddingValue = 8 - (inputLength % 8);
      final outputLength = inputLength + paddingValue;

      final output = Uint8List(outputLength);
      for (var i = 0; i < inputLength; ++i) {
        output[i] = input[i];
      }
      output.fillRange(outputLength - paddingValue, outputLength, paddingValue);

      return output;
    };

    var encodedPassword =
        base64.encode(blowfish.encode(padPKCS5(utf8.encode(password))));

    response = await request('UserLoginRequest.php', {
      'RegionCode': _getRegionName(region),
      'UserId': username,
      'Password': encodedPassword
    });

    if (response['status'] != 200) {
      throw 'Login error';
    }

    language = response['CustomerInfo']['Language'];

    switch (region) {
      case CarwingsRegion.World:
      case CarwingsRegion.USA:
      case CarwingsRegion.Europe:
      case CarwingsRegion.Canada:
      case CarwingsRegion.Australia:
        gdcUserId = response['vehicle']?['profile']?['gdcUserId'] ?? '';
        dcmId = response['vehicle']['profile']['dcmId'];
        timeZoneProvided = response['CustomerInfo']['Timezone'];
        // With more than one vehicle this value makes little sense
        try {
          modelYear = int.parse(response['vehicle']['profile']['modelyear']);
        } catch (e) {}

        loggedIn = true;

        vehicles = <CarwingsVehicle>[];
        // For some odd reason VehicleInfoList is not present on 1th gen Leafs
        // It is only there for 2nd gen Leafs
        if (response['VehicleInfoList'] != null) {
          for (Map vehicleInfo in response['VehicleInfoList']['vehicleInfo']) {
            vehicles.add(CarwingsVehicle(
                this,
                vehicleInfo['custom_sessionid'],
                vehicleInfo['vin'],
                vehicleInfo['nickname'],
                response['CustomerInfo']['VehicleInfo']['UserVehicleBoundTime'],
                response['CustomerInfo']['VehicleInfo']['CarName']));
          }
        } else {
          for (Map vehicleInfo in response['vehicleInfo']) {
            vehicles.add(CarwingsVehicle(
                this,
                vehicleInfo['custom_sessionid'],
                vehicleInfo['vin'],
                vehicleInfo['nickname'],
                response['CustomerInfo']['VehicleInfo']['UserVehicleBoundTime'],
                response['CustomerInfo']['VehicleInfo']['CarName']));
          }
        }
        break;
      case CarwingsRegion.Japan:
        gdcUserId = response['vehicle']?['profile']?['gdcUserId'] ?? '';
        dcmId = response['CustomerInfo']['VehicleInfo']['DCMID'];
        timeZoneProvided = response['CustomerInfo']['Timezone'];

        loggedIn = true;

        vehicles = <CarwingsVehicle>[];
        if (response['CustomerInfo']['VehicleInfo'] != null) {
          var vehicleInfo = response['CustomerInfo']['VehicleInfo'];
          vehicles.add(CarwingsVehicle(
            this,
            vehicleInfo['custom_sessionid'],
            vehicleInfo['VIN'],
            response['CustomerInfo']['Nickname'],
            vehicleInfo['UserVehicleBoundTime'],
            vehicleInfo['CarName'],
          ));
        } else {
          throw 'Login error';
        }
    }

    vehicle = vehicles.first;

    return vehicle;
  }

  String get timeZone =>
      timeZoneOverride != null && timeZoneOverride!.isNotEmpty
          ? timeZoneOverride
          : timeZoneProvided;

  bool get isFirstGeneration => modelYear < 18;

  setTimeZoneOverride(String? tz) {
    timeZoneOverride = tz;
  }

  String getRegion() {
    return _getRegionName(region);
  }

  String _getRegionName(CarwingsRegion region) {
    switch (region) {
      case CarwingsRegion.USA:
        return 'NNA';
      case CarwingsRegion.Europe:
        return 'NE';
      case CarwingsRegion.Canada:
        return 'NCI';
      case CarwingsRegion.Australia:
        return 'NMA';
      case CarwingsRegion.Japan:
        return 'NML';
      default:
        return 'NE';
    }
  }

  _print(message) {
    if (debug) {
      print('\$ $message');
      debugLog.add('\$ $message');
    }
  }
}
