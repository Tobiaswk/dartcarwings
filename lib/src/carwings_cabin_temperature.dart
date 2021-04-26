class CarwingsCabinTemperature {
  late DateTime timeStamp;
  late double temperature;

  CarwingsCabinTemperature(Map params) {
    timeStamp = DateTime.now();
    this.temperature = double.parse(params['Inc_temp'].toString());
  }

  CarwingsCabinTemperature.latest(Map params) {
    var data = params['CabinTemp'];

    //this.timeStamp = new DateFormat('yyyy/M/d H:m').parse(data['DateAndTime']);
    this.timeStamp = DateTime.now();
    this.temperature = double.parse(data['Inc_temp'].toString());
  }
}
