package_json = require '../package.json'
OrderExport = require './orderexport'

exports.process = (msg, cfg, next, snapshot) ->
  orderexport = new OrderExport
    config:
      client_id: cfg.sphereClientId
      client_secret: cfg.sphereClientSecret
      project_key: cfg.sphereProjectKey
    timeout: 60000
    user_agent: "#{package_json.name} - elasticio - #{package_json.version}",

  orderexport.elasticio msg, cfg, next, snapshot
