OrderExport = require('./lib/orderexport');

exports.process = function(msg, cfg, next, snapshot) {
  config = {
    client_id: cfg.sphereClientId,
    client_secret: cfg.sphereClientSecret,
    project_key: cfg.sphereProjectKey
  };
  var orderExport = new OrderExport({
    config: config
  });
  orderExport.elasticio(msg, cfg, next, snapshot);
}
