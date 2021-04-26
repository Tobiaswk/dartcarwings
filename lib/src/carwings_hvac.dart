class CarwingsHVAC {
  late bool isRunning;
  late var preACTemp;
  late var preACTempUnit;
  late var incTemp;

  CarwingsHVAC(Map params) {
    var racr = params['RemoteACRecords'];

    // Sometimes racr is simply empty
    // If it is empty HVAC is not on (an assumption)
    this.isRunning = racr.length > 0 &&
        racr['OperationResult'] != null &&
        racr['OperationResult'].toString().startsWith('START') &&
        racr['RemoteACOperation'] == 'START';
    if (racr.length > 0) {
      this.preACTemp = racr['PreAC_temp'];
      this.preACTempUnit = racr['PreAC_unit'];
      this.incTemp = racr['Inc_temp'];
    }
  }
}
