import 'package:intl/intl.dart';

class CarwingsBattery {
  NumberFormat numberFormat = NumberFormat('0');

  late DateTime dateTime;
  late double batteryLevelCapacity;
  late double batteryLevel;
  bool isConnected = false;
  bool isCharging = false;
  bool isQuickCharging = false;
  bool isConnectedToQuickCharging = false;
  late String batteryPercentage;
  String?
      battery12thBar; // Leaf using 12th bar system; present as 12ths; 5/12 etc.
  late String cruisingRangeAcOffKm;
  late String cruisingRangeAcOffMiles;
  late String cruisingRangeAcOnKm;
  late String cruisingRangeAcOnMiles;
  late Duration timeToFullTrickle;
  late Duration timeToFullL2;
  late Duration timeToFullL2_6kw;
  String? chargingkWLevelText;
  String? chargingRemainingText;

  CarwingsBattery.batteryLatest(Map params) {
    var recs = params['BatteryStatusRecords'];
    var bs = recs['BatteryStatus'];

    /// "TargetDate" or "NotificationDateAndTime" needs to be used in the future
    /// These are in UTC
    /// This looks ugly but the API has some strange behavior that we have to
    /// deal with.
    try {
      this.dateTime = DateFormat('yyyy/MM/dd H:m')
          .parse(recs['TargetDate'], true)
          .toLocal();
    } catch (e) {
      try {
        this.dateTime =
            DateFormat('d-M-yyyy H:m').parse(recs['OperationDateAndTime']);
      } catch (e) {
        try {
          this.dateTime =
              DateFormat('dd-MMM-yyyy H:m').parse(recs['OperationDateAndTime']);
        } catch (e) {
          try {
            this.dateTime = DateFormat('DD.MMM yyyy HH:mm')
                .parse(recs['OperationDateAndTime']);
          } catch (e) {
            try {
              this.dateTime = DateFormat('MMM DD, yyyy HH:mm a')
                  .parse(recs['OperationDateAndTime']);
            } catch (e) {
              try {
                this.dateTime = DateFormat('d-MMM-yyyy HH:mm')
                    .parse(recs['OperationDateAndTime']);
              } catch (e) {
                this.dateTime = DateTime.now(); // Just use now
              }
            }
          }
        }
      }
    }
    this.batteryLevelCapacity = double.parse(bs['BatteryCapacity']);
    this.batteryLevel = double.parse(bs['BatteryRemainingAmount']);
    this.isConnected = recs['PluginState'] != 'NOT_CONNECTED';
    this.isCharging = bs['BatteryChargingStatus'] != 'NOT_CHARGING';
    this.isQuickCharging = bs['BatteryChargingStatus'] == 'RAPIDLY_CHARGING';
    this.isConnectedToQuickCharging = recs['PluginState'] == 'QC_CONNECTED';
    this.batteryPercentage = NumberFormat('0.0')
            .format((this.batteryLevel * 100) / this.batteryLevelCapacity)
            .toString() +
        '%';

    // If "SOC" is available; use it
    if (bs['SOC'] != null && bs['SOC']['Value'] != null) {
      double SOC = double.parse(bs['SOC']['Value']);
      this.batteryPercentage = NumberFormat('0.0').format(SOC).toString() + '%';
    }
    if (batteryLevelCapacity >= 0.0 && batteryLevelCapacity <= 12.0) {
      /// Leaf using 12th bar system; present as 12ths; 5/12 etc.
      /// [batteryLevelCapacity] can be lower than 12 because of degradation
      /// We explicitly use 12 instead of [batteryLevelCapacity]
      this.battery12thBar = '${numberFormat.format(batteryLevel)} / 12';

      /// Although we have the [battery12thBar] we also calculate a battery
      /// percentage.
      /// The notation below has been taken from;
      ///   https://www.mynissanleaf.com/viewtopic.php?t=2390
      /// Specifically we use the "Driving" "Low" notation.
      this.batteryPercentage = NumberFormat('0.0')
              .format({
                12: 92,
                11: 84,
                10: 78,
                9: 71,
                8: 64,
                7: 57,
                6: 51,
                5: 44,
                4: 36,
                3: 29,
                2: 22,
                1: 15,
                0: 8,
              }[batteryLevel])
              .toString() +
          '%';
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
        Duration(minutes: _timeRemaining(recs['TimeRequiredToFull']));
    this.timeToFullL2 =
        Duration(minutes: _timeRemaining(recs['TimeRequiredToFull200']));
    this.timeToFullL2_6kw =
        Duration(minutes: _timeRemaining(recs['TimeRequiredToFull200_6kW']));
    if (isQuickCharging) {
      chargingkWLevelText = 'left to charge at ~40kW';
      chargingRemainingText = 'usually 50 mins';
    } else if (timeToFullTrickle.inHours != 0) {
      chargingkWLevelText = 'left to charge at ~1kW';
      chargingRemainingText =
          '${timeToFullTrickle.inHours} hrs ${timeToFullTrickle.inMinutes % 60} mins';
    } else if (timeToFullL2.inHours != 0) {
      chargingkWLevelText = 'left to charge at ~3kW';
      chargingRemainingText =
          '${timeToFullL2.inHours} hrs ${timeToFullL2.inMinutes % 60} mins';
    } else if (timeToFullL2_6kw.inHours != 0) {
      chargingkWLevelText = 'left to charge at ~6kW';
      chargingRemainingText =
          '${timeToFullL2_6kw.inHours} hrs ${timeToFullL2_6kw.inMinutes % 60} mins';
    }
  }

  int _timeRemaining(Map? params) {
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
