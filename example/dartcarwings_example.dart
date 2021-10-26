import 'package:dartcarwings/dartcarwings.dart';

main() {
  CarwingsSession session = new CarwingsSession(debug: true);

  session.login(username: "username", password: "password").then((vehicle) {
    vehicle.requestBatteryStatusLatest().then((battery) {
      print(battery?.batteryPercentage);
      print(battery?.cruisingRangeAcOffKm);
      print(battery?.cruisingRangeAcOnKm);
      print(battery?.timeToFullTrickle.inHours);
      print(battery?.timeToFullL2_6kw.inHours);
    });
  });
}
