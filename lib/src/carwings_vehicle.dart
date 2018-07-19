import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:dartcarwings/src/carwings_stats_daily.dart';
import 'package:dartcarwings/src/carwings_hvac.dart';
import 'package:dartcarwings/src/carwings_location.dart';
import 'package:dartcarwings/src/carwings_stats_monthly.dart';
import 'package:dartcarwings/src/carwings_battery.dart';
import 'package:dartcarwings/src/carwings_session.dart';

class CarwingsVehicle {
  var _executeTimeFormatter = new DateFormat('yyyy-MM-dd H:m');
  var _displayExecuteTimeFormatter = new DateFormat('dd-MM-yyyy H:m');
  var _targetMonthFormatter = new DateFormat('yyyyMM');
  var _targetDateFormatter = new DateFormat('yyyy-MM-dd');

  CarwingsSession _session;
  var vin;
  var nickname;
  var _boundTime;
  var model;

  CarwingsVehicle(CarwingsSession session, Map params) {
    this._session = session;
    this.vin = params["VehicleInfoList"]["vehicleInfo"][0]["vin"];
    this.nickname = params["VehicleInfoList"]["vehicleInfo"][0]["nickname"];
    this._boundTime =
        params["CustomerInfo"]["VehicleInfo"]["UserVehicleBoundTime"];
    this.model = params['CustomerInfo']['VehicleInfo']['CarName'];
  }

  DateTime getLastDriven() {
    return DateTime.parse(this._boundTime);
  }

  Future<CarwingsBattery> requestBatteryStatus() async {
    var response =
        await _session.requestWithRetry("BatteryStatusCheckRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "UserId": _session.gdcUserId
    });

    CarwingsBattery battery;

    while (true) {
      battery = await _getBatteryStatus(response['resultKey']);
      if (battery != null) {
        return battery;
      }
      await waitForResponse();
    }
  }

  Future<CarwingsBattery> _getBatteryStatus(String resultKey) async {
    var response =
        await _session.requestWithRetry("BatteryStatusCheckResultRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "resultKey": resultKey
    });
    if (response['responseFlag'] == '1') {
      return new CarwingsBattery(response);
    }
    return null;
  }

  Future<Null> requestClimateControlOn() async {
    var response = await _session.requestWithRetry("ACRemoteRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz
    });

    while (true) {
      if (await _getClimateControlOnStatus(response['resultKey'])) {
        return;
      }
      await waitForResponse();
    }
  }

  Future<bool> _getClimateControlOnStatus(String resultKey) async {
    var response = await _session.requestWithRetry("ACRemoteResult.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "UserId": _session.gdcUserId,
      "resultKey": resultKey
    });
    if (response['responseFlag'] == '1') {
      return true;
    }
    return false;
  }

  Future<Null> requestClimateControlOff() async {
    var response = await _session.requestWithRetry("ACRemoteOffRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz
    });

    while (true) {
      if (await _getClimateControlOffStatus(response['resultKey'])) {
        return;
      }
      await waitForResponse();
    }
  }

  Future<bool> _getClimateControlOffStatus(String resultKey) async {
    var response = await _session.requestWithRetry("ACRemoteOffResult.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "UserId": _session.gdcUserId,
      "resultKey": resultKey
    });
    if (response['responseFlag'] == '1') {
      return true;
    }
    return false;
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<bool> requestClimateControlSchedule(DateTime startTime) async {
    var response =
        await _session.requestWithRetry("ACRemoteUpdateRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "ExecuteTime": _executeTimeFormatter.format(startTime.toUtc())
    });
    if (response['status'] == 200) {
      return true;
    }
    return false;
  }

  Future<bool> requestClimateControlScheduleCancel() async {
    var response =
        await _session.requestWithRetry("ACRemoteCancelRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz
    });
    if (response['status'] == 200) {
      return true;
    }
    return false;
  }

  // For some weird reason DisplayExecuteTime returns time in local time zone
  // ExecuteTime is also available is in UTC/GMT
  Future<DateTime> requestClimateControlScheduleGet() async {
    var response =
        await _session.requestWithRetry("GetScheduledACRemoteRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz
    });
    if (response['status'] == 200) {
      if (response['DisplayExecuteTime'] != '') {
        return _displayExecuteTimeFormatter
            .parse(response['DisplayExecuteTime']);
      }
    }
    return null;
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<bool> requestChargingStart(DateTime startTime) async {
    var response =
        await _session.requestWithRetry("BatteryRemoteChargingRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "ExecuteTime": _executeTimeFormatter.format(startTime.toUtc())
    });
    if (response['status'] == 200) {
      return true;
    }
    return false;
  }

  Future<CarwingsStatsMonthly> requestStatisticsMonthly(DateTime month) async {
    var response =
        await _session.requestWithRetry("PriceSimulatorDetailInfoRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "TargetMonth": _targetMonthFormatter.format(month)
    });
    if (response['status'] == 200) {
      return new CarwingsStatsMonthly(response);
    }
    return null;
  }

  Future<CarwingsStatsDaily> requestStatisticsDaily() async {
    var response = await _session
        .requestWithRetry("DriveAnalysisBasicScreenRequestEx.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz
    });
    if (response['status'] == 200) {
      return new CarwingsStatsDaily(response);
    }
    return null;
  }

  Future<CarwingsHVAC> requestHVACStatus() async {
    var response =
        await _session.requestWithRetry("RemoteACRecordsRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "TimeFrom": _boundTime
    });
    if (response['status'] == 200) {
      return new CarwingsHVAC(response);
    }
    return null;
  }

  Future<CarwingsBattery> requestBatteryStatusLatest() async {
    var response =
        await _session.requestWithRetry("BatteryStatusRecordsRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "TimeFrom": _boundTime
    });
    if (response['status'] == 200) {
      return new CarwingsBattery.batteryLatest(response);
    }
    return null;
  }

  Future<CarwingsLocation> requestLocation() async {
    var response = await _session.requestWithRetry("MyCarFinderRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "UserId": _session.gdcUserId
    });

    while (true) {
      CarwingsLocation carwingsLocation =
          await _getLocationStatus(response['resultKey']);
      if (carwingsLocation != null) {
        return carwingsLocation;
      }
      await waitForResponse();
    }
  }

  Future<CarwingsLocation> _getLocationStatus(String resultKey) async {
    var response =
        await _session.requestWithRetry("MyCarFinderResultRequest.php", {
      "RegionCode": _session.getRegion(),
      "lg": _session.language,
      "DMCID": _session.dcmId,
      "VIN": vin,
      "tz": _session.tz,
      "resultKey": resultKey
    });
    if (response['responseFlag'] == '1') {
      return new CarwingsLocation(response['lat'], response['lng']);
    }
    return null;
  }

  Future<Null> waitForResponse({waitSeconds = 10}) {
    return new Future.delayed(new Duration(seconds: waitSeconds));
  }
}
