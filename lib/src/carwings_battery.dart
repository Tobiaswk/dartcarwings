import 'package:intl/intl.dart';

class CarwingsBattery {
  NumberFormat numberFormat = new NumberFormat('0');

  DateTime timeStamp;
  double batteryLevelCapacity;
  double batteryLevel;
  bool isConnected = false;
  bool isCharging = false;
  bool isQuickCharging = false;
  bool isConnectedToQuickCharging = false;
  String batteryPercentage;
  String battery12thBar; // Leaf using 12th bar system; present as 12ths; 5/12 etc.
  String cruisingRangeAcOffKm;
  String cruisingRangeAcOffMiles;
  String cruisingRangeAcOnKm;
  String cruisingRangeAcOnMiles;
  Duration timeToFullTrickle;
  Duration timeToFullL2;
  Duration timeToFullL2_6kw;
  String chargingkWLevelText;
  String chargingRemainingText;

  CarwingsBattery(Map params) {
    //this.timeStamp = new DateFormat('yyyy-MM-dd H:m:s').parse(params['timeStamp']);
    this.timeStamp = new DateTime.now(); // Always now
    this.batteryLevelCapacity = double.parse(params['batteryCapacity']);
    this.batteryLevel = double.parse(params['batteryDegradation']);
    this.isConnected = params['pluginState'] != 'NOT_CONNECTED';
    this.isCharging = params['charging'] == 'YES';
    this.isQuickCharging = params['chargeMode'] == 'RAPIDLY_CHARGING';
    this.isConnectedToQuickCharging = params['pluginState'] == 'QC_CONNECTED';
    this.batteryPercentage =
        ((this.batteryLevel * 100) / this.batteryLevelCapacity).toString() +
            '%';
    this.cruisingRangeAcOffKm =
        numberFormat.format(double.parse(params['cruisingRangeAcOff']) / 1000) +
            ' km';
    this.cruisingRangeAcOffMiles = numberFormat
        .format(double.parse(params['cruisingRangeAcOff']) * 0.0006213712) +
        ' mi';
    this.cruisingRangeAcOnKm =
        numberFormat.format(double.parse(params['cruisingRangeAcOn']) / 1000) +
            ' km';
    this.cruisingRangeAcOnMiles = numberFormat
        .format(double.parse(params['cruisingRangeAcOn']) * 0.0006213712) +
        ' mi';
    this.timeToFullTrickle =
    new Duration(minutes: _timeRemaining(params['TimeRequiredToFull']));
    this.timeToFullL2 =
    new Duration(minutes: _timeRemaining(params['TimeRequiredToFull200']));
    this.timeToFullL2_6kw = new Duration(
        minutes: _timeRemaining(params['TimeRequiredToFull200_6kW']));
  }

  CarwingsBattery.batteryLatest(Map params) {
    var recs = params["BatteryStatusRecords"];
    var bs = recs['BatteryStatus'];

    // TargetDate or NotificationDateAndTime needs to be used in the future
    // These are in UTC
    // Until better timezone support has been added to Dart this will do
    try {
      this.timeStamp =
          new DateFormat('d-M-yyyy H:m').parse(recs['OperationDateAndTime']);
    } catch (e) {
      try {
        this.timeStamp = new DateFormat('dd-MMM-yyyy H:m')
            .parse(recs['OperationDateAndTime']);
      } catch (e) {
        this.timeStamp = new DateTime.now(); // Just use now
      }
    }
    this.batteryLevelCapacity = double.parse(bs['BatteryCapacity']);
    this.batteryLevel = double.parse(bs['BatteryRemainingAmount']);
    this.isConnected = recs['PluginState'] != 'NOT_CONNECTED';
    this.isCharging = bs['BatteryChargingStatus'] != 'NOT_CHARGING';
    this.isQuickCharging = bs['BatteryChargingStatus'] == 'RAPIDLY_CHARGING';
    this.isConnectedToQuickCharging = recs['PluginState'] == 'QC_CONNECTED';
    this.batteryPercentage = new NumberFormat('0.0')
        .format((this.batteryLevel * 100) / this.batteryLevelCapacity)
        .toString() +
        '%';
    // If SOC is available; use it
    if (bs['SOC'] != null && bs['SOC']['Value'] != null) {
      double SOC = double.parse(bs['SOC']['Value']);
      this.batteryPercentage =
          new NumberFormat('0.0').format(SOC).toString() + '%';
    }
    if (batteryLevelCapacity >= 0.0 && batteryLevelCapacity <= 12.0) {
      // Leaf using 12th bar system; present as 12ths; 5/12 etc.
      // batteryLevelCapacity can be lower than 12 because of degradation
      this.battery12thBar =
      "${new NumberFormat('0').format(batteryLevel)} / ${new NumberFormat(
          '0').format(batteryLevelCapacity)}";
    }
    this.cruisingRangeAcOffKm =
        numberFormat.format(double.parse(recs['CruisingRangeAcOff']) / 1000) +
            ' km';
    this.cruisingRangeAcOffMiles = numberFormat
        .format(double.parse(recs['CruisingRangeAcOff']) * 0.0006213712) +
        ' mi';
    this.cruisingRangeAcOnKm =
        numberFormat.format(double.parse(recs['CruisingRangeAcOn']) / 1000) +
            ' km';
    this.cruisingRangeAcOnMiles = numberFormat
        .format(double.parse(recs['CruisingRangeAcOn']) * 0.0006213712) +
        ' mi';
    this.timeToFullTrickle =
    new Duration(minutes: _timeRemaining(recs['TimeRequiredToFull']));
    this.timeToFullL2 =
    new Duration(minutes: _timeRemaining(recs['TimeRequiredToFull200']));
    this.timeToFullL2_6kw = new Duration(
        minutes: _timeRemaining(recs['TimeRequiredToFull200_6kW']));
    if (isQuickCharging) {
      chargingkWLevelText = "left to charge at ~40kW";
      chargingRemainingText = "usually 50 mins";
    } else if (timeToFullTrickle.inHours != 0) {
      chargingkWLevelText = "left to charge at ~1kW";
      chargingRemainingText =
      "${(timeToFullTrickle.inMinutes / 60).floor()} hrs ${timeToFullTrickle
          .inMinutes % 60} mins";
    } else if (timeToFullL2.inHours != 0) {
      chargingkWLevelText = "left to charge at ~3kW";
      chargingRemainingText =
      "${(timeToFullL2.inMinutes / 60).floor()} hrs ${timeToFullL2.inMinutes %
          60} mins";
    } else if (timeToFullL2_6kw.inHours != 0) {
      chargingkWLevelText = "left to charge at ~6kW";
      chargingRemainingText =
      "${(timeToFullL2_6kw.inMinutes / 60).floor()} hrs ${timeToFullL2_6kw
          .inMinutes % 60} mins";
    }
  }

  int _timeRemaining(Map params) {
    int minutes = 0;
    if (params != null) {
      if (params['hours'] != null && params['hours'] != '') {
        minutes = 60 * int.parse(params['hours']);
      } else if (params['HourRequiredToFull'] != null &&
          params['HourRequiredToFull'] != '') {
        minutes = 60 * int.parse(params['HourRequiredToFull']);
      }
      if (params['minutes'] != null && params['minutes'] != '') {
        minutes += int.parse(params['minutes']);
      } else if (params['MinutesRequiredToFull'] != null &&
          params['MinutesRequiredToFull'] != '') {
        minutes += int.parse(params['MinutesRequiredToFull']);
      }
    }
    return minutes;
  }
}
