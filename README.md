# dartcarwings

A library for the Nissan Leaf Carwings API.

Through the Carwings API you can ask your vehicle for the latest data, see current battery and charging statuses, see the current climate control state, start or stop climate control remotely, remotely start charging, and retrieve the last known location of the vehicle.

## Usage

A simple usage example:

    import 'package:dartcarwings/dartcarwings.dart';

    main() {
      CarwingsSession session = new CarwingsSession("username", "password");

      session.login().then((vehicle) {
        vehicle.requestBatteryStatus().then((battery) {
            print(battery.batteryPercentage);
            print(battery.cruisingRangeAcOffKm);
            print(battery.cruisingRangeAcOnKm);
        });
      });
    }
