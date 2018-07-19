import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dartcarwings/src/carwings_vehicle.dart';

enum CarwingsRegion { USA, Europe, Canada, Australia, Japan }

class CarwingsSession {
  final String baseUrl = "https://gdcportalgw.its-mo.com/api_v180117_NE/gdc/";

  // Result of the call to InitialApp.php, which appears to
  // always be the same.  It'll probably break at some point but
  // for now... skip it.
  final String blowfishKey = "uyI5Dj9g8VCOFDnBRUbr3g";

  // Extracted from the NissanConnect EV app
  final String initialAppStrings = "geORNtsZe5I4lRGjG9GZiA";

  bool debug;

  var username;
  var password;
  CarwingsRegion region;
  var vin = '';
  var customSessionID = '';
  bool loggedIn = false;
  var gdcUserId;
  var tz;
  var language;
  var dcmId;

  CarwingsVehicle vehicle;

  CarwingsSession(this.username, this.password, [this.region = CarwingsRegion.Europe, this.debug = false]);

  String _pkcs5Padding(String data) {
    int byteNum = data.length;
    int packingLength = 8 - byteNum % 8;
    return data.padRight(byteNum + packingLength, "$packingLength");
  }

  // pkcs5 padding
  // and blowfish encryption is sadly done server-side
  // due to missing support in Dart
  _requestBlowfish(String password, String key) async {
    http.Response response = await http.get(
        "https://wkjeldsen.dk/nissan/blowfish.php?password=$password&key=$key");

    return response.body;
  }

  dynamic requestWithRetry(String endpoint, Map params) async {
    dynamic response = await request(endpoint, params);

    var status = response['status'];

    if (status != null && status >= 400) {
      print('carwings error; logging in and trying request again: $response');

      login();

      response = await request(endpoint, params);
    }
    return response;
  }

  dynamic request(String endpoint, Map params) async {
    params['initial_app_strings'] = initialAppStrings;
    if (customSessionID != null) {
      params['custom_sessionid'] = customSessionID;
    } else {
      params['custom_sessionid'] = '';
    }

    print('invoking carwings API: $endpoint');
    print('params: $params');

    http.Response response =
        await http.post("${baseUrl}${endpoint}", body: params);

    dynamic json = JSON.decode(response.body);

    print('result: $json');

    return json;
  }

  Future<CarwingsVehicle> login([Future<String> blowfishEncrypt(String encryptKey)]) async {
    loggedIn = false;
    customSessionID = '';

    var response = await request(
        "InitialApp.php", {"RegionCode": _region(region), "lg": "en-US"});

    var encodedPassword;

    if(blowfishEncrypt != null) {
      encodedPassword = blowfishEncrypt(response['baseprm']);
    } else {
      encodedPassword = await _requestBlowfish(password, response['baseprm']);
    }

    response = await request("UserLoginRequest.php", {
      "RegionCode": _region(region),
      "UserId": username,
      "Password": encodedPassword
    });

    if(response['status'] != 200) {
      throw 'Login error';
    }

    if (response["VehicleInfoList"] != null) {
      customSessionID =
          response["VehicleInfoList"]["vehicleInfo"][0]["custom_sessionid"];
    } else {
      customSessionID = response["vehicleInfo"][0]["custom_sessionid"];
    }

    language = response['CustomerInfo']["Language"];
    gdcUserId = response["vehicle"]["profile"]["gdcUserId"];
    dcmId = response["vehicle"]["profile"]["dcmId"];
    vin = response["vehicle"]["profile"]["vin"];
    tz = response["CustomerInfo"]["Timezone"];

    loggedIn = true;

    vehicle = new CarwingsVehicle(this, response);

    return vehicle;
  }

  CarwingsVehicle getVehicle() {
    return vehicle;
  }

  bool isLoggedIn() {
    return loggedIn;
  }

  String getRegion() {
    return _region(region);
  }

  String _region(CarwingsRegion region) {
    switch (region) {
      case CarwingsRegion.USA:
        return "NNA";
      case CarwingsRegion.Europe:
        return "NE";
      case CarwingsRegion.Canada:
        return "NCI";
      case CarwingsRegion.Australia:
        return "NMA";
      case CarwingsRegion.Japan:
        return "NML";
      default:
        return "NE";
    }
  }
}
