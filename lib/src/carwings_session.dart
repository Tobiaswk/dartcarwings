import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dartcarwings/src/carwings_vehicle.dart';

enum CarwingsRegion { World, USA, Europe, Canada, Australia, Japan }

class CarwingsSession {
  final String baseUrl = 'https://gdcportalgw.its-mo.com/api_v200413_NE/gdc/';

  // Result of the call to InitialApp.php, which appears to
  // always be the same.  It'll probably break at some point but
  // for now... skip it.
  final String blowfishKey = 'uyI5Dj9g8VCOFDnBRUbr3g';

  // Extracted from the NissanConnect EV app
  final String initialAppStrings = '9s5rfKVuMrT03RtzajWNcA';

  bool debug;
  List<String> debugLog = List<String>();

  // If this is set it will override the time zone returned from Carwings API
  var timeZoneOverride;

  var username;
  var password;
  CarwingsRegion region;
  bool loggedIn = false;
  var gdcUserId;
  var timeZoneProvided;
  var language;
  var dcmId;
  int modelYear = 0;

  var blowfishEncryptCallback;

  CarwingsVehicle vehicle;
  List<CarwingsVehicle> vehicles;

  CarwingsSession({this.debug = false, this.timeZoneOverride});

  Future<dynamic> requestWithRetry(String endpoint, Map params) async {
    dynamic response = await request(endpoint, params);

    var status = response['status'];

    if (status != null && status >= 400) {
      _print('Carwings API; logging in and trying request again: $response');

      await login(
          username: username,
          password: password,
          blowfishEncryptCallback: blowfishEncryptCallback);

      response = await request(endpoint, params);
    }
    return response;
  }

  Future<dynamic> request(String endpoint, Map params) async {
    params['initial_app_str'] = initialAppStrings;
    if (vehicle != null && vehicle.customSessionID != null) {
      params['custom_sessionid'] = vehicle.customSessionID;
    } else {
      params['custom_sessionid'] = '';
    }

    _print('Invoking Carwings API: $endpoint');
    _print('Params: $params');

    http.Response response =
        await http.post('${baseUrl}${endpoint}', body: params);

    dynamic jsonData = json.decode(response.body);

    _print('Result: $jsonData');

    return jsonData;
  }

  Future<CarwingsVehicle> login(
      {String username,
      String password,
      CarwingsRegion region = CarwingsRegion.Europe,
      Future<String> blowfishEncryptCallback(
          String key, String password)}) async {
    this.username = username;
    this.password = password;
    this.region = region;
    this.blowfishEncryptCallback = blowfishEncryptCallback;

    loggedIn = false;

    var response = await request('InitialApp_v2.php',
        {'RegionCode': _getRegionName(region), 'lg': 'en-US'});

    var encodedPassword =
        await blowfishEncryptCallback(response['baseprm'], password);

    response = await request('UserLoginRequest.php', {
      'RegionCode': _getRegionName(region),
      'UserId': username,
      'Password': encodedPassword
    });

    if (response['status'] != 200) {
      throw 'Login error';
    }

    language = response['CustomerInfo']['Language'];
    gdcUserId = response['vehicle']['profile']['gdcUserId'];
    dcmId = response['vehicle']['profile']['dcmId'];
    timeZoneProvided = response['CustomerInfo']['Timezone'];
    // With more than one vehicle this value makes little sense
    try {
      modelYear = int.parse(response['vehicle']['profile']['modelyear']);
    } catch (e) {}

    loggedIn = true;

    vehicles = List<CarwingsVehicle>();
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
    vehicle = vehicles.first;

    return vehicle;
  }

  String get timeZone => timeZoneOverride != null && timeZoneOverride.isNotEmpty
      ? timeZoneOverride
      : timeZoneProvided;

  bool get isFirstGeneration => modelYear < 18;

  setTimeZoneOverride(String tz) {
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
