import 'package:intl/intl.dart';

class CarwingsCabinTemperature {
  DateTime timeStamp;
  var temperature;

  CarwingsCabinTemperature(Map params) {
    timeStamp = DateTime.now();
    this.temperature = params['Inc_temp'];
  }

  CarwingsCabinTemperature.latest(Map params) {
    var data = params["CabinTemp"];

    //this.timeStamp = new DateFormat('yyyy/M/d H:m').parse(data['DateAndTime']);
    this.timeStamp = DateTime.now();
    this.temperature = data['Inc_temp'];
  }

}
