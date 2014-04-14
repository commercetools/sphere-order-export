{Logger} = require 'sphere-node-utils'
package_json = require '../package.json'

module.exports = class extends Logger

  @appName: "#{package_json.name}-#{package_json.version}"
