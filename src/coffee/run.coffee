_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
package_json = require '../package.json'
Logger = require './logger'
{ProjectCredentialsConfig} = require 'sphere-node-utils'
fs = require 'fs'
argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .describe('projectKey', 'your SPHERE.IO project-key')
  .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
  .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
  .describe('fetchHours', 'Number of hours to fetch modified orders')
  .describe('outputDir', 'Folder to store resulting XML files in')
  .describe('logLevel', 'log level for file logging')
  .describe('logDir', 'directory to store logs')
  .describe('timeout', 'Set timeout for requests')
  .default('outputDir', '.')
  .default('logLevel', 'info')
  .default('logDir', '.')
  .default('fetchHours', 0) # by default don't restrict on modifications
  .default('timeout', 60000)
  .demand(['projectKey'])
  .argv

logger = new Logger
  streams: [
    { level: 'error', stream: process.stderr }
    { level: argv.logLevel, path: "#{argv.logDir}/sphere-order-xml-export_#{argv.projectKey}.log" }
  ]

process.on 'SIGUSR2', -> logger.reopenFileStreams()

credentialsConfig = ProjectCredentialsConfig.create()
.then (credentials) ->
  options =
    config: credentials.enrichCredentials
      project_key: argv.projectKey
      client_id: argv.clientId
      client_secret: argv.clientSecret
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
    logConfig:
      logger: logger

  sphere = new SphereClient options
  options.sphere_client = sphere
  mapping = new Mapping options

  sphere.orders.last("#{argv.fetchHours}h").perPage(0).fetch().then (result) =>
    mapping.processOrders(result.body.results)
    .then (xmlOrders) =>
      logger.info "Storing #{_.size xmlOrders} file(s) to '#{argv.outputDir}'."
      _.each xmlOrders, (entry) =>
        content = entry.xml.end(pretty: true, indent: '  ', newline: "\n")
        fileName = "#{entry.id}.xml"
        fs.writeFile "#{argv.outputDir}/#{fileName}", content, (err) ->
          if err
            logger.error err
            process.exit 2

.fail (res) ->
  logger.error res
  process.exit 1
