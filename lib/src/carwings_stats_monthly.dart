import 'package:intl/intl.dart';

class CarwingsStatsMonthly {
  late DateTime dateTime;
  late String electricCostScale;
  late String mileageUnit;
  late String totalNumberOfTrips;
  late String totalkWhPerMileage;
  late String totalMileagePerKWh;
  late String totalConsumptionKWh;
  late String totalTravelDistanceMileage;
  late String totalCO2Reduction;

  CarwingsStatsMonthly(Map params) {
    var r = params['PriceSimulatorDetailInfoResponsePersonalData'];
    var t = r['PriceSimulatorTotalInfo'];

    NumberFormat numberFormat = NumberFormat('0.00');

    this.electricCostScale =
        params['PriceSimulatorDetailInfoResponsePersonalData']
            ['ElectricCostScale'];

    this.dateTime = DateFormat('MMM/y').parse(r['DisplayMonth']);
    this.totalNumberOfTrips = t['TotalNumberOfTrips'];
    this.totalConsumptionKWh =
        numberFormat.format(double.parse(t['TotalPowerConsumptTotal'])) +
            ' kWh';
    // For some reason electricCostScale can vary from country to country
    if (electricCostScale == 'kWh/km') {
      this.mileageUnit = 'km';
      this.totalTravelDistanceMileage = NumberFormat('0')
              .format(double.parse(t['TotalTravelDistance']) / 1000) +
          ' ' +
          mileageUnit;
      this.totalkWhPerMileage = numberFormat.format(
              double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000)) +
          ' kWh/' +
          mileageUnit;
      this.totalMileagePerKWh = numberFormat.format(1 /
              (double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000))) +
          ' ' +
          mileageUnit +
          '/kWh';
    } else if (electricCostScale == 'km/kWh') {
      this.mileageUnit = 'km';
      this.totalTravelDistanceMileage = NumberFormat('0')
              .format(double.parse(t['TotalTravelDistance']) / 1000) +
          ' ' +
          mileageUnit;
      this.totalkWhPerMileage = numberFormat.format(
              double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000)) +
          ' kWh/' +
          mileageUnit;
      this.totalMileagePerKWh = numberFormat.format(1 /
              (double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000))) +
          ' ' +
          mileageUnit +
          '/kWh';
    } else if (electricCostScale == 'kWh/100km') {
      this.mileageUnit = 'km';
      this.totalTravelDistanceMileage = NumberFormat('0')
              .format(double.parse(t['TotalTravelDistance']) / 1000) +
          ' ' +
          mileageUnit;
      this.totalkWhPerMileage = numberFormat.format(
              double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000)) +
          ' kWh/' +
          mileageUnit;
      this.totalMileagePerKWh = numberFormat.format(1 /
              (double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) / 1000))) +
          ' ' +
          mileageUnit +
          '/kWh';
    } else if (electricCostScale == 'miles/kWh') {
      this.mileageUnit = 'mi';
      this.totalTravelDistanceMileage = NumberFormat('0')
              .format(double.parse(t['TotalTravelDistance']) * 0.0006213712) +
          ' ' +
          mileageUnit;
      // For some odd reason it seems with miles/kWh that the values returned are
      // actually swapped to kWh/miles; I'm lost for words
      this.totalkWhPerMileage = numberFormat.format(
              double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) * 0.0006213712)) +
          ' kWh/' +
          mileageUnit;
      this.totalMileagePerKWh = numberFormat.format(1 /
              (double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) * 0.0006213712))) +
          ' ' +
          mileageUnit +
          '/kWh';
    } else /*if(electricCostScale == 'kWh/miles')*/ {
      this.mileageUnit = 'mi';
      this.totalTravelDistanceMileage = NumberFormat('0')
              .format(double.parse(t['TotalTravelDistance']) * 0.0006213712) +
          ' ' +
          mileageUnit;
      this.totalkWhPerMileage = numberFormat.format(
              double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) * 0.0006213712)) +
          ' kWh/' +
          mileageUnit;
      this.totalMileagePerKWh = numberFormat.format(1 /
              (double.parse(t['TotalPowerConsumptTotal']) /
                  (double.parse(t['TotalTravelDistance']) * 0.0006213712))) +
          ' ' +
          mileageUnit +
          '/kWh';
    }

    this.totalCO2Reduction = t['TotalCO2Reductiont'] + ' kg';
  }
}
