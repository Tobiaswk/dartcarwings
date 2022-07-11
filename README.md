# dartcarwings

A Dart client library for the Nissan Carwings API for vehicles produced prior to May 2019.

Through the Carwings API you can ask your vehicle for the latest data, see current battery and charging statuses, see the current climate control state, start or stop climate control remotely, remotely start charging, and retrieve the last known location of the vehicle.

## Usage

A simple usage example:

    import 'package:dartcarwings/dartcarwings.dart';

    main() {
      CarwingsSession session = new CarwingsSession(debug: true);

      session
        .login(username: "username", password: "password")
        .then((vehicle) {
            vehicle.requestBatteryStatus().then((battery) {
                print(battery.batteryPercentage);
                print(battery.cruisingRangeAcOffKm);
                print(battery.cruisingRangeAcOnKm);
            });
        });
    }
