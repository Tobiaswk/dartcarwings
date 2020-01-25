import 'package:intl/intl.dart';

class CarwingsUnitCalculator {
  NumberFormat numberFormat00 = NumberFormat('0.00');
  NumberFormat numberFormat0 = NumberFormat('0');

  String mileagePerKwh(
      double distanceInMeters, double consumption, String electricCostScale) {
    if (electricCostScale == 'kWh/km') {
      return numberFormat00
              .format(1 / (consumption / toKilometers(distanceInMeters))) +
          ' km/kWh';
    } else if (electricCostScale == 'km/kWh') {
      return numberFormat00
              .format(1 / (consumption / toKilometers(distanceInMeters))) +
          ' km/kWh';
    } else if (electricCostScale == 'kWh/100km') {
      numberFormat00
              .format(1 / (consumption / toKilometers(distanceInMeters))) +
          ' km/kWh';
    } else if (electricCostScale == 'miles/kWh') {
      return numberFormat00
              .format(1 / (consumption / toMiles(distanceInMeters))) +
          ' mi/kWh';
    } else
    /*if(electricCostScale == 'kWh/miles')*/ {
      return numberFormat00
              .format(1 / (consumption / toMiles(distanceInMeters))) +
          ' mi/kWh';
    }
  }

  String kWhPerMileage(
      double distanceInMeters, double consumption, String electricCostScale) {
    if (electricCostScale == 'kWh/km') {
      return numberFormat00
              .format(consumption / toKilometers(distanceInMeters)) +
          ' kWh/km';
    } else if (electricCostScale == 'km/kWh') {
      return numberFormat00
              .format(consumption / toKilometers(distanceInMeters)) +
          ' kWh/km';
    } else if (electricCostScale == 'kWh/100km') {
      return numberFormat00
              .format(consumption / toKilometers(distanceInMeters)) +
          ' kWh/km';
    } else if (electricCostScale == 'miles/kWh') {
      return numberFormat00.format(consumption / toMiles(distanceInMeters)) +
          ' kWh/mi';
    } else
    /*if(electricCostScale == 'kWh/miles')*/ {
      return numberFormat00.format(consumption / toMiles(distanceInMeters)) +
          ' kWh/mi';
    }
  }

  String distance(double distanceInMeters, String electricCostScale) {
    if (electricCostScale == 'kWh/km') {
      return numberFormat0.format(toKilometers(distanceInMeters)) + ' km';
    } else if (electricCostScale == 'km/kWh') {
      return numberFormat0.format(toKilometers(distanceInMeters)) + ' km';
    } else if (electricCostScale == 'kWh/100km') {
      return numberFormat0.format(toKilometers(distanceInMeters)) + ' km';
    } else if (electricCostScale == 'miles/kWh') {
      return numberFormat0.format(toMiles(distanceInMeters)) + ' mi';
    } else
    /*if(electricCostScale == 'kWh/miles')*/ {
      return numberFormat0.format(toMiles(distanceInMeters)) + ' mi';
    }
  }

  String consumption(double consumption) {
    return numberFormat00.format(consumption) + ' kWh';
  }

  double toKilometers(double distanceInMeters) {
    return distanceInMeters / 1000;
  }

  double toMiles(double distanceInMeters) {
    return distanceInMeters * 0.0006213712;
  }
}
