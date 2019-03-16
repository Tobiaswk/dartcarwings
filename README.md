# dartcarwings

A Dart library for the Nissan Carwings API.

Through the Carwings API you can ask your vehicle for the latest data, see current battery and charging statuses, see the current climate control state, start or stop climate control remotely, remotely start charging, and retrieve the last known location of the vehicle.

## Usage

A simple usage example:

    import 'package:dartcarwings/dartcarwings.dart';

    main() {
      CarwingsSession session = new CarwingsSession(debug: true);

      session
        .login(
           username: "username",
           password: "password",
           blowfishEncryptCallback: (String key, String password) async {
             // No native support for Blowfish encryption with Dart
             // Use external service
           })
        .then((vehicle) {
            vehicle.requestBatteryStatus().then((battery) {
                print(battery.batteryPercentage);
                print(battery.cruisingRangeAcOffKm);
                print(battery.cruisingRangeAcOnKm);
            });
        });
    }
