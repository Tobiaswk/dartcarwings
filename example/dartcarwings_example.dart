//import 'package:dartcarwings/dartcarwings.dart';
import 'package:dartcarwings/dartcarwings.dart';

main() {
  CarwingsSession session = new CarwingsSession("username", "password");

  session.login().then((vehicle) {
    //vehicle.requestClimateControlSchedule(new DateTime.now().add(new Duration(minutes: 10)));
    //vehicle.requestClimateControlScheduleGet();
    //vehicle.requestClimateControlScheduleCancel();
    //vehicle.requestClimateControlOff();
/*    vehicle.requestBatteryStatus().then((battery) {
      print(battery.batteryPercentage);
      print(battery.cruisingRangeAcOffKm);
      print(battery.cruisingRangeAcOnKm);
    });*/
      vehicle.requestStatisticsDaily().then((stats) {
        print(stats.KWhPerMileage);
        print(stats.mileagePerKWh);
        print(stats.accelerationWh);
        print(stats.regenerativeWh);
        print(stats.auxWh);
        print(stats.mileageLevel);
        print(stats.date);
      });
/*    vehicle.requestBatteryStatusLatest().then((battery) {
      print(battery.batteryPercentage);
      print(battery.cruisingRangeAcOffKm);
      print(battery.cruisingRangeAcOnKm);
      print(battery.timeToFullTrickle.inHours);
      print(battery.timeToFullL2_6kw.inHours);
    });*/
    //leaf.requestClimateControlOff().then((_) => print('climate control off'));
/*    vehicle.requestStatisticsMonthly(new DateTime(2018, 7)).then((stats) {
      if(stats != null) {
        print(stats.totalNumberOfTrips);
        print(stats.totalConsumptionKWh);
        print(stats.totalkWhPerMileage);
        print(stats.totalTravelDistanceMileage);
        print(stats.totalCO2Reduction);
        print(stats.electricCostScale);
        print(stats.mileageUnit);
      }
    });*/
/*    vehicle.requestLocation().then((location) {
      print(location.latitude);
      print(location.longitude);
    });*/
/*    vehicle.requestHVACStatus().then((hvac) {
      if(hvac != null) {
        print(hvac.isRunning);
        print(hvac.preACTemp);
        print(hvac.incTemp);
        print(hvac.preACTempUnit);
      }
    });*/
  });
}
