import 'package:intl/intl.dart';

class CarwingsStatsDaily {
  DateTime date;
  String mileagePerKWh;
  String KWhPerMileage;
  String mileageLevel;
  String accelerationWh;
  String accelerationLevel;
  String regenerativeWh;
  String regenerativeLevel;
  String auxWh;
  String auxLevel;
  String electricCostScale;

  CarwingsStatsDaily(Map params) {
    var summary =
        params['DriveAnalysisBasicScreenResponsePersonalData']['DateSummary'];

    NumberFormat numberFormat = new NumberFormat('0.00');

    this.date = new DateFormat('yyyy-MM-dd').parse(summary['TargetDate']);
    this.electricCostScale =
        params["DriveAnalysisBasicScreenResponsePersonalData"]
            ["ElectricCostScale"];
    if (electricCostScale == 'kWh/km') {
      this.KWhPerMileage =
          numberFormat.format(double.parse(summary['ElectricMileage'])) +
              ' kWh/km';
      this.mileagePerKWh =
          numberFormat.format((1 / double.parse(summary['ElectricMileage']))) +
              ' km/kWh';
    } else {
      this.KWhPerMileage =
          numberFormat.format(double.parse(summary['ElectricMileage'])) +
              ' kWh/mi';
      this.mileagePerKWh =
          numberFormat.format((1 / double.parse(summary['ElectricMileage']))) +
              ' mi/kWh';
    }
    this.mileageLevel = summary['ElectricMileageLevel'];
    this.accelerationWh =
        numberFormat.format(double.parse(summary['PowerConsumptMoter'])) + ' Wh';
    this.accelerationLevel = summary['PowerConsumptMoterLevel'];
    this.regenerativeWh =
        numberFormat.format(double.parse(summary['PowerConsumptMinus'])) + ' Wh';
    this.regenerativeLevel = summary['PowerConsumptMinusLevel'];
    this.auxWh =
        numberFormat.format(double.parse(summary['PowerConsumptAUX'])) + ' Wh';
    this.auxLevel = summary['PowerConsumptAUXLevel'];
  }
}
