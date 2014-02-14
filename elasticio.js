Mapping = require '../lib/mapping'

exports.process = function(msg, cfg, next, snapshot) {
  config = {
    client_id: cfg.sphereClientId,
    client_secret: cfg.sphereClientSecret,
    project_key: cfg.sphereProjectKey
  };
  var mapping = new Mapping({
    config: config
  });
  mapping.elasticio(msg, cfg, next, snapshot);
}
