import 'dart:async';

import 'package:dartcarwings/src/carwings_battery.dart';
import 'package:dartcarwings/src/carwings_cabin_temperature.dart';
import 'package:dartcarwings/src/carwings_hvac.dart';
import 'package:dartcarwings/src/carwings_location.dart';
import 'package:dartcarwings/src/carwings_session.dart';
import 'package:dartcarwings/src/carwings_stats_daily.dart';
import 'package:dartcarwings/src/carwings_stats_monthly.dart';
import 'package:dartcarwings/src/carwings_stats_trips.dart';
import 'package:intl/intl.dart';

class CarwingsVehicle {
  final int MAX_RETRIES = 15;

  var _executeTimeFormatter = DateFormat('yyyy-MM-dd H:m');
  var _targetMonthFormatter = DateFormat('yyyyMM');

  CarwingsSession session;
  var customSessionID;
  var vin;
  var nickname;
  var boundTime;
  var model;

  CarwingsVehicle(this.session, this.customSessionID, this.vin, this.nickname,
      this.boundTime, this.model);

  DateTime getLastDriven() {
    return DateTime.parse(this.boundTime);
  }

  Future<CarwingsBattery?> requestBatteryStatus() async {
    var response =
        await session.requestWithRetry('BatteryStatusCheckRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'UserId': session.gdcUserId
    });

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      if (await _getBatteryStatus(response['resultKey'])) {
        return requestBatteryStatusLatest();
      }
      await waitForResponse();
    }

    return null;
  }

  Future<bool> _getBatteryStatus(String resultKey) async {
    var response =
        await session.requestWithRetry('BatteryStatusCheckResultRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'resultKey': resultKey
    });

    return responseFlagHandler(response);
  }

  Future requestClimateControlOn() async {
    var response = await session.requestWithRetry('ACRemoteRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
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
    var response = await session.requestWithRetry('ACRemoteResult.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'UserId': session.gdcUserId,
      'resultKey': resultKey
    });

    return responseFlagHandler(response);
  }

  Future requestClimateControlOff() async {
    var response = await session.requestWithRetry('ACRemoteOffRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone
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
    var response = await session.requestWithRetry('ACRemoteOffResult.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'UserId': session.gdcUserId,
      'resultKey': resultKey
    });

    return responseFlagHandler(response);
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<bool> requestClimateControlSchedule(DateTime startTime) async {
    var response = await session.requestWithRetry('ACRemoteUpdateRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'ExecuteTime': _executeTimeFormatter.format(startTime.toUtc()),
    });

    return responseValidHandler(response);
  }

  Future<bool> requestClimateControlScheduleCancel() async {
    var response = await session.requestWithRetry('ACRemoteCancelRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone
    });

    return responseValidHandler(response);
  }

  // For some weird reason DisplayExecuteTime returns time in local time zone
  // ExecuteTime is also available is in UTC/GMT
  Future<DateTime?> requestClimateControlScheduleGet() async {
    var response =
        await session.requestWithRetry('GetScheduledACRemoteRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone
    });

    if (responseValidHandler(response)) {
      if (response['ExecuteTime'] != '') {
        return _executeTimeFormatter
            .parse(response['ExecuteTime'], true)
            .toLocal();
      }
    }

    return null;
  }

  // For some weird reason ExecuteTime is always in UTC/GMT
  // regardless of tz
  Future<bool> requestChargingStart(DateTime startTime) async {
    var response =
        await session.requestWithRetry('BatteryRemoteChargingRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'ExecuteTime': _executeTimeFormatter.format(startTime.toUtc())
    });

    return responseValidHandler(response);
  }

  Future<CarwingsStatsMonthly?> requestStatisticsMonthly(DateTime month) async {
    var response =
        await session.requestWithRetry('PriceSimulatorDetailInfoRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'TargetMonth': _targetMonthFormatter.format(month)
    });

    if (responseValidHandler(response)) {
      return CarwingsStatsMonthly(response);
    }

    return null;
  }

  Future<CarwingsStatsTrips?> requestStatisticsMonthlyTrips(
      DateTime month) async {
    var response =
        await session.requestWithRetry('PriceSimulatorDetailInfoRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'TargetMonth': _targetMonthFormatter.format(month)
    });

    if (responseValidHandler(response)) {
      return CarwingsStatsTrips(response);
    }

    return null;
  }

  Future<CarwingsStatsDaily?> requestStatisticsDaily() async {
    var response = await session
        .requestWithRetry('DriveAnalysisBasicScreenRequestEx.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone
    });

    if (responseValidHandler(response)) {
      return CarwingsStatsDaily(response);
    }

    return null;
  }

  Future<CarwingsHVAC?> requestHVACStatus() async {
    var response =
        await session.requestWithRetry('RemoteACRecordsRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'TimeFrom': boundTime
    });

    if (responseValidHandler(response)) {
      return CarwingsHVAC(response);
    }

    return null;
  }

  Future<CarwingsCabinTemperature?> requestCabinTemperatureLatest() async {
    var response = await session.requestWithRetry('CheckCabinTemp.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'TimeFrom': boundTime
    });

    if (responseValidHandler(response)) {
      return CarwingsCabinTemperature.latest(response);
    }

    return null;
  }

  Future<CarwingsCabinTemperature?> requestCabinTemperature() async {
    var response = await session
        .requestWithRetry('GetInteriorTemperatureRequestForNsp.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone
    });

    CarwingsCabinTemperature? carwingsCabinTemperature;

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      carwingsCabinTemperature =
          await _getCabinTemperature(response['resultKey']);
      if (carwingsCabinTemperature != null) {
        return carwingsCabinTemperature;
      }
      await waitForResponse();
    }

    return null;
  }

  Future<CarwingsCabinTemperature?> _getCabinTemperature(
      String resultKey) async {
    var response = await session
        .requestWithRetry('GetInteriorTemperatureResultForNsp.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'UserId': session.gdcUserId,
      'resultKey': resultKey
    });

    if (responseFlagHandler(response)) {
      return CarwingsCabinTemperature(response);
    }

    return null;
  }

  Future<CarwingsBattery?> requestBatteryStatusLatest() async {
    var response =
        await session.requestWithRetry('BatteryStatusRecordsRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'TimeFrom': boundTime
    });

    if (responseValidHandler(response)) {
      return CarwingsBattery.batteryLatest(response);
    }

    return null;
  }

  Future<CarwingsLocation?> requestLocation() async {
    var response = await session.requestWithRetry('MyCarFinderRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'UserId': session.gdcUserId
    });

    CarwingsLocation? carwingsLocation;

    int retries = MAX_RETRIES;
    while (responseValidHandler(response, retries: retries--)) {
      carwingsLocation = await _getLocationStatus(response['resultKey']);
      if (carwingsLocation != null) {
        return carwingsLocation;
      }
      await waitForResponse();
    }

    return null;
  }

  Future<CarwingsLocation?> _getLocationStatus(String resultKey) async {
    var response =
        await session.requestWithRetry('MyCarFinderResultRequest.php', {
      'custom_sessionid': customSessionID ?? '',
      'RegionCode': session.getRegion(),
      'lg': session.language,
      'DCMID': session.dcmId,
      'VIN': vin,
      'tz': session.timeZone,
      'resultKey': resultKey
    });

    if (responseFlagHandler(response)) {
      return CarwingsLocation(response['lat'], response['lng']);
    }

    return null;
  }

  bool responseValidHandler(response, {retries = -1}) =>
      response['status'] != 200 || retries == 0 ? throw 'Error' : true;

  bool responseFlagHandler(response) => response['status'] != 200
      ? throw 'Error'
      : response['responseFlag'] == '1';

  Future waitForResponse({waitSeconds = 5}) {
    return Future.delayed(Duration(seconds: waitSeconds));
  }
}
