import 'dart:async';
import 'package:dartcarwings/src/carwings_cabin_temperature.dart';
import 'package:dartcarwings/src/carwings_stats_trips.dart';
import 'package:intl/intl.dart';
import 'package:dartcarwings/src/carwings_stats_daily.dart';
import 'package:dartcarwings/src/carwings_hvac.dart';
import 'package:dartcarwings/src/carwings_location.dart';
import 'package:dartcarwings/src/carwings_stats_monthly.dart';
import 'package:dartcarwings/src/carwings_battery.dart';
import 'package:dartcarwings/src/carwings_session.dart';

class CarwingsVehicle {
  final int MAX_RETRIES = 8;

  var _executeTimeFormatter = new DateFormat('yyyy-MM-dd H:m');
  var _displayExecuteTimeFormatter = new DateFormat('dd-MM-yyyy H:m');
  var _targetMonthFormatter = new DateFormat('yyyyMM');
  var _targetDateFormatter = new DateFormat('yyyy-MM-dd');

  CarwingsSession session;
  var customSessionID;
  var vin;
  var nickname;
  var boundTime;
  var model;

  CarwingsVehicle(this.session, this.customSessionID, this.vin, this.nickname, this.boundTime, this.model);

  DateTime getLastDriven() {
    return DateTime.parse(this.boundTime);
  }

  Future<CarwingsBattery> requestBatteryStatus() async {
    var response =
        await session.requestWithRetry("BatteryStatusCheckRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "UserId": session.gdcUserId
    });

    CarwingsBattery battery;

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      battery = await _getBatteryStatus(response['resultKey']);
      if (battery != null) {
        return battery;
      }
      await waitForResponse();
    }
  }

  Future<CarwingsBattery> _getBatteryStatus(String resultKey) async {
    var response =
        await session.requestWithRetry("BatteryStatusCheckResultRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "resultKey": resultKey
    });
    if (responseFlagHandler(response)) {
      return new CarwingsBattery(response);
    }
    return null;
  }

  Future<Null> requestClimateControlOn() async {
    var response = await session.requestWithRetry("ACRemoteRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      if (await _getClimateControlOnStatus(response['resultKey'])) {
        return;
      }
      await waitForResponse();
    }
  }

  Future<bool> _getClimateControlOnStatus(String resultKey) async {
    var response = await session.requestWithRetry("ACRemoteResult.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "UserId": session.gdcUserId,
      "resultKey": resultKey
    });
    if (responseFlagHandler(response)) {
      return true;
    }
    return false;
  }

  Future<Null> requestClimateControlOff() async {
    var response = await session.requestWithRetry("ACRemoteOffRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      if (await _getClimateControlOffStatus(response['resultKey'])) {
        return;
      }
      await waitForResponse();
    }
  }

  Future<bool> _getClimateControlOffStatus(String resultKey) async {
    var response = await session.requestWithRetry("ACRemoteOffResult.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "UserId": session.gdcUserId,
      "resultKey": resultKey
    });
    if (responseFlagHandler(response)) {
      return true;
    }
    return false;
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<Null> requestClimateControlSchedule(DateTime startTime) async {
    var response =
        await session.requestWithRetry("ACRemoteUpdateRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "ExecuteTime": _executeTimeFormatter.format(startTime.toUtc())
    });
    if (responseValidHandler(response)) {
      return;
    }
  }

  Future<Null> requestClimateControlScheduleCancel() async {
    var response =
        await session.requestWithRetry("ACRemoteCancelRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });
    if (responseValidHandler(response)) {
      return;
    }
  }

  // For some weird reason DisplayExecuteTime returns time in local time zone
  // ExecuteTime is also available is in UTC/GMT
  Future<DateTime> requestClimateControlScheduleGet() async {
    var response =
        await session.requestWithRetry("GetScheduledACRemoteRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });
    if (responseValidHandler(response)) {
      if (response['DisplayExecuteTime'] != '') {
        return _displayExecuteTimeFormatter
            .parse(response['DisplayExecuteTime']);
      }
    }
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<Null> requestChargingStart(DateTime startTime) async {
    var response =
        await session.requestWithRetry("BatteryRemoteChargingRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "ExecuteTime": _executeTimeFormatter.format(startTime.toUtc())
    });
    if (responseValidHandler(response)) {
      return;
    }
  }

  Future<CarwingsStatsMonthly> requestStatisticsMonthly(DateTime month) async {
    var response =
        await session.requestWithRetry("PriceSimulatorDetailInfoRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "TargetMonth": _targetMonthFormatter.format(month)
    });
    if (responseValidHandler(response)) {
      return new CarwingsStatsMonthly(response);
    }
  }

  Future<CarwingsStatsTrips> requestStatisticsMonthlyTrips(DateTime month) async {
    var response =
    await session.requestWithRetry("PriceSimulatorDetailInfoRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "TargetMonth": _targetMonthFormatter.format(month)
    });
    if (responseValidHandler(response)) {
      return new CarwingsStatsTrips(response);
    }
  }

  Future<CarwingsStatsDaily> requestStatisticsDaily() async {
    var response = await session
        .requestWithRetry("DriveAnalysisBasicScreenRequestEx.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });
    if (responseValidHandler(response)) {
      return new CarwingsStatsDaily(response);
    }
  }

  Future<CarwingsHVAC> requestHVACStatus() async {
    var response =
        await session.requestWithRetry("RemoteACRecordsRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "TimeFrom": boundTime
    });
    if (responseValidHandler(response)) {
      return new CarwingsHVAC(response);
    }
  }

  Future<CarwingsCabinTemperature> requestCabinTemperatureLatest() async {
    var response =
    await session.requestWithRetry("CheckCabinTemp.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "TimeFrom": boundTime
    });
    if (responseValidHandler(response)) {
      return new CarwingsCabinTemperature.latest(response);
    }
  }

  Future<CarwingsCabinTemperature> requestCabinTemperature() async {
    var response = await session.requestWithRetry("GetInteriorTemperatureRequestForNsp.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone
    });

    CarwingsCabinTemperature carwingsCabinTemperature;

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      carwingsCabinTemperature = await _getCabinTemperature(response['resultKey']);
      if (carwingsCabinTemperature != null) {
        return carwingsCabinTemperature;
      }
      await waitForResponse();
    }
  }

  Future<CarwingsCabinTemperature> _getCabinTemperature(String resultKey) async {
    var response = await session.requestWithRetry("GetInteriorTemperatureResultForNsp.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "UserId": session.gdcUserId,
      "resultKey": resultKey
    });
    if (responseFlagHandler(response)) {
      return new CarwingsCabinTemperature(response);;
    }
    return null;
  }

  Future<CarwingsBattery> requestBatteryStatusLatest() async {
    var response =
        await session.requestWithRetry("BatteryStatusRecordsRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "TimeFrom": boundTime
    });
    if (responseValidHandler(response)) {
      return new CarwingsBattery.batteryLatest(response);
    }
  }

  Future<CarwingsLocation> requestLocation() async {
    var response = await session.requestWithRetry("MyCarFinderRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "UserId": session.gdcUserId
    });

    CarwingsLocation carwingsLocation;

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      carwingsLocation =
          await _getLocationStatus(response['resultKey']);
      if (carwingsLocation != null) {
        return carwingsLocation;
      }
      await waitForResponse();
    }
  }

  Future<CarwingsLocation> _getLocationStatus(String resultKey) async {
    var response =
        await session.requestWithRetry("MyCarFinderResultRequest.php", {
      "RegionCode": session.getRegion(),
      "lg": session.language,
      "DCMID": session.dcmId,
      "VIN": vin,
      "tz": session.timeZone,
      "resultKey": resultKey
    });
    if (responseFlagHandler(response)) {
      return new CarwingsLocation(response['lat'], response['lng']);
    }
    return null;
  }

  bool responseValidHandler(response, {retries = -1}) =>
      response['status'] != 200 || retries == 0 ? throw 'Error' : true;

  bool responseFlagHandler(response) => response['status'] != 200
      ? throw 'Error'
      : response['responseFlag'] == '1';

  Future<Null> waitForResponse({waitSeconds = 10}) {
    return new Future.delayed(new Duration(seconds: waitSeconds));
  }
}
