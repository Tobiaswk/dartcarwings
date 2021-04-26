import 'package:dartcarwings/src/carwings_stats_trip.dart';
import 'package:dartcarwings/src/carwings_stats_trip_detail.dart';
import 'package:dartcarwings/src/carwings_unit_calculator.dart';
import 'package:intl/intl.dart';

class CarwingsStatsTrips {
  List<CarwingsStatsTrip> trips = [];

  CarwingsStatsTrips(Map params) {
    CarwingsUnitCalculator carwingsUnitCalculator = CarwingsUnitCalculator();

    var electricCostScale =
        params['PriceSimulatorDetailInfoResponsePersonalData']
            ['ElectricCostScale'];

    List statsPerDate = params['PriceSimulatorDetailInfoResponsePersonalData']
            ['PriceSimulatorDetailInfoDateList']['PriceSimulatorDetailInfoDate']
        .reversed
        .toList();

    for (var stats in statsPerDate) {
      CarwingsStatsTrip carwingsTrip = CarwingsStatsTrip();
      carwingsTrip.date = DateFormat('yyyy-MM-dd').parse(stats['TargetDate']);

      double tripTotalTravelDistance = 0;
      double tripTotalKWhPerMileage = 0;
      double tripTotalMileagePerKWh = 0;
      double tripTotalConsumptionKWh = 0;
      double tripTotalCO2Reduction = 0;

      var tripDetails = stats['PriceSimulatorDetailInfoTripList']
          ['PriceSimulatorDetailInfoTrip'];
      for (var tripDetail in tripDetails) {
        CarwingsStatsTripDetail carwingsTripDetail = CarwingsStatsTripDetail();
        carwingsTripDetail.date =
            DateFormat('yyyy-MM-dd').parse(stats['TargetDate']);
        carwingsTripDetail.number = int.parse(tripDetail['TripId']);
        carwingsTripDetail.consumptionKWh = carwingsUnitCalculator
            .consumption(double.parse(tripDetail['PowerConsumptTotal']) / 1000);
        carwingsTripDetail.travelDistanceMileage =
            carwingsUnitCalculator.distance(
                double.parse(tripDetail['TravelDistance']), electricCostScale);
        carwingsTripDetail.kWhPerMileage = carwingsUnitCalculator.kWhPerMileage(
            double.parse(tripDetail['TravelDistance']),
            double.parse(tripDetail['PowerConsumptTotal']) / 1000,
            electricCostScale);
        carwingsTripDetail.mileagePerKWh = carwingsUnitCalculator.mileagePerKwh(
            double.parse(tripDetail['TravelDistance']),
            double.parse(tripDetail['PowerConsumptTotal']) / 1000,
            electricCostScale);
        carwingsTripDetail.CO2Reduction =
            tripDetail['CO2Reduction'] + ' kg CO2';

        carwingsTrip.tripsDetails.add(carwingsTripDetail);

        tripTotalConsumptionKWh +=
            double.parse(tripDetail['PowerConsumptTotal']);
        tripTotalTravelDistance += double.parse(tripDetail['TravelDistance']);
        tripTotalKWhPerMileage +=
            double.parse(tripDetail['PowerConsumptTotal']);
        tripTotalMileagePerKWh +=
            double.parse(tripDetail['PowerConsumptTotal']);
        tripTotalCO2Reduction += double.parse(tripDetail['CO2Reduction']);
      }

      carwingsTrip.consumptionKWh =
          carwingsUnitCalculator.consumption(tripTotalConsumptionKWh / 1000);
      carwingsTrip.travelDistanceMileage = carwingsUnitCalculator.distance(
          tripTotalTravelDistance, electricCostScale);
      carwingsTrip.kWhPerMileage = carwingsUnitCalculator.kWhPerMileage(
          tripTotalTravelDistance,
          tripTotalKWhPerMileage / 1000,
          electricCostScale);
      carwingsTrip.mileagePerKWh = carwingsUnitCalculator.mileagePerKwh(
          tripTotalTravelDistance,
          tripTotalMileagePerKWh / 1000,
          electricCostScale);
      carwingsTrip.CO2Reduction =
          NumberFormat('0').format(tripTotalCO2Reduction) + ' kg CO2';

      trips.add(carwingsTrip);
    }
  }
}
