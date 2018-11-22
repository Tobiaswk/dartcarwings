import 'package:dartcarwings/src/carwings_stats_trip_detail.dart';

class CarwingsStatsTrip {
  DateTime date;
  String kWhPerMileage;
  String mileagePerKWh;
  String consumptionKWh;
  String travelDistanceMileage;
  String CO2Reduction;

  List<CarwingsStatsTripDetail> tripsDetails = List();
}
