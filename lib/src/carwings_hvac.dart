class CarwingsHVAC {
  bool isRunning;
  var preACTemp;
  var preACTempUnit;
  var incTemp;

  CarwingsHVAC(Map params) {
    var racr = params['RemoteACRecords'];

    this.isRunning = racr['OperationResult'] != null &&
        racr['OperationResult'].toString().startsWith('START') &&
        racr['RemoteACOperation'] == 'START';
    this.preACTemp = racr['PreAC_temp'];
    this.preACTempUnit = racr['PreAC_unit'];
    this.incTemp = racr['Inc_temp'];
  }
}
