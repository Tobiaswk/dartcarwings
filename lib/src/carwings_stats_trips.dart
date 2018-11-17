import 'package:dartcarwings/src/carwings_stats_trip_detail.dart';
import 'package:dartcarwings/src/carwings_unit_calculator.dart';
import 'package:intl/intl.dart';

class CarwingsStatsTrips {
  List<CarwingsStatsTripDetail> trips;

  CarwingsStatsTrips(Map params) {
    CarwingsUnitCalculator carwingsUnitCalculator =
        new CarwingsUnitCalculator();

    var electricCostScale =
        params["PriceSimulatorDetailInfoResponsePersonalData"]
            ['ElectricCostScale'];

    var statsPerDate = params['PriceSimulatorDetailInfoResponsePersonalData']
        ['PriceSimulatorDetailInfoDateList']['PriceSimulatorDetailInfoDate'];

    trips = List();
    for (var stats in statsPerDate) {
      for (var trip in stats['PriceSimulatorDetailInfoTripList']
          ['PriceSimulatorDetailInfoTrip']) {
        CarwingsStatsTripDetail carwingsTripDetail = CarwingsStatsTripDetail();
        carwingsTripDetail.date =
            new DateFormat('yyyy-MM-dd').parse(stats['TargetDate']);
        carwingsTripDetail.number = int.parse(trip['TripId']);
        carwingsTripDetail.consumptionKWh = carwingsUnitCalculator
            .consumption(double.parse(trip['PowerConsumptTotal'])/1000);
        carwingsTripDetail.travelDistanceMileage = carwingsUnitCalculator
            .distance(double.parse(trip['TravelDistance']), electricCostScale);
        carwingsTripDetail.kWhPerMileage = carwingsUnitCalculator.kWhPerMileage(
            double.parse(trip['TravelDistance']),
            double.parse(trip['PowerConsumptTotal'])/1000,
            electricCostScale);
        carwingsTripDetail.mileagePerKWh = carwingsUnitCalculator.mileagePerKwh(
            double.parse(trip['TravelDistance']),
            double.parse(trip['PowerConsumptTotal'])/1000,
            electricCostScale);
        carwingsTripDetail.CO2Reduction = trip['CO2Reduction'] + ' kg CO2';
        trips.add(carwingsTripDetail);
      }
    }
  }
}
