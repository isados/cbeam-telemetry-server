var app = require('../server/app');

// Configure EVA unit 1
var eva = new app.Dictionary('EVA1', 'eva1');
eva.addMeasurement('temperature', 'EVA1.temp', [
  {
    units: 'degrees',
    format: 'integer',
    min: 0,
    max: 100
  }
], {
  topic: 'eva/temperature/1',
  timeseries: 'Temperature1',
  persist: true
});
eva.addMeasurement('luminosity', 'EVA1.lum', [
  {
    units: 'points',
    format: 'integer',
    min: 0,
    max: 255
  }
], {
  topic: 'bitraf/luminosity/1',
  timeseries: 'Luminosity1',
  persist: true
});
eva.addMeasurement('hall', 'EVA1.hall', [
  {
    units: 'points',
    format: 'integer',
    min: 0,
    max: 255
  }
], {
  topic: 'bitraf/hall/1',
  timeseries: 'Hall1',
  persist: true
});
eva.addMeasurement('counter', 'EVA1.cnt', [
  {
    units: 'points',
    format: 'integer',
    min: 0,
    max: 255
  }
], {
  topic: 'bitraf/counter/1',
  timeseries: 'Counter1',
  persist: true
});

// Start the server
var server = new app.Server({
  host: process.env.HOST || 'localhost',
  port: process.env.PORT || 8080,
  wss_port: process.env.WSS_PORT || 8082,
  broker: process.env.MSGFLO_BROKER || 'mqtt://localhost',
  dictionaries: [eva],
  history: {
    host: process.env.INFLUX_HOST || 'localhost',
    db: process.env.INFLUX_DB || 'cbeam'
  }
});
server.start(function (err) {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log('Server listening in ' + server.config.port);
});
