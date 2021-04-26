import 'package:dartcarwings/src/carwings_stats_trip_detail.dart';

class CarwingsStatsTrip {
  late DateTime date;
  late String kWhPerMileage;
  late String mileagePerKWh;
  late String consumptionKWh;
  late String travelDistanceMileage;
  late String CO2Reduction;

  List<CarwingsStatsTripDetail> tripsDetails = [];
}
