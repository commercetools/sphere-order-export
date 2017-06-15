path = require 'path'
_ = require 'underscore'
{ExtendedLogger, ProjectCredentialsConfig} = require 'sphere-node-utils'
package_json = require '../package.json'

# Will return optimist with basic params
exports.getDefaultOptions = ->
  require('optimist')
    .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
    .describe('projectKey', 'your SPHERE.IO project-key')
    .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
    .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
    .describe('accessToken', 'an OAuth access token for the SPHERE.IO API')
    .describe('sphereHost', 'SPHERE.IO API host to connect to')
    .describe('sphereProtocol', 'SPHERE.IO API protocol to connect to')
    .describe('sphereAuthHost', 'SPHERE.IO OAuth host to connect to')
    .describe('sphereAuthProtocol', 'SPHERE.IO OAuth protocol to connect to')
    .describe('perPage', 'Number of orders to be fetched per page')
    .describe('targetDir', 'the folder where exported files are saved')
    .describe('fileWithTimestamp', 'whether exported file should contain a timestamp')
    .describe('where', 'where predicate used to filter orders exported. More info here http://dev.commercetools.com/http-api.html#predicates')
    .describe('logLevel', 'log level for file logging')
    .describe('logDir', 'directory to store logs')
    .describe('timeout', 'Set timeout for requests')
    .default('perPage', 100)
    .default('targetDir', path.join(__dirname,'../exports'))
    .default('fileWithTimestamp', false)
    .default('logLevel', 'info')
    .default('logDir', '.')
    .default('timeout', 60000)
    .default('exportCSVAsStream', false)
    .demand(['projectKey'])

# Will return a logger
exports.getLogger = (argv, name = package_json.name) ->
  logger = new ExtendedLogger
    additionalFields:
      project_key: argv.projectKey
    logConfig:
      name: "#{name}-#{package_json.version}"
      streams: [
        { level: 'error', stream: process.stderr }
        { level: argv.logLevel, path: "#{argv.logDir}/#{name}.log" }
      ]
      silent: Boolean argv.logSilent
  logger

exports.ensureCredentials = (argv) ->
  if argv.accessToken
    Promise.resolve
      config:
        project_key: argv.projectKey
      access_token: argv.accessToken
  else
    ProjectCredentialsConfig.create()
      .then (credentials) ->
        config: credentials.enrichCredentials
          project_key: argv.projectKey
          client_id: argv.clientId
          client_secret: argv.clientSecret

exports.getClientOptions = (credentials, argv) ->
  clientOptions = _.extend credentials,
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
  clientOptions.host = argv.sphereHost if argv.sphereHost
  clientOptions.protocol = argv.sphereProtocol if argv.sphereProtocol

  if argv.sphereAuthHost
    clientOptions.oauth_host = argv.sphereAuthHost
    clientOptions.rejectUnauthorized = false
  clientOptions.oauth_protocol = argv.sphereAuthProtocol if argv.sphereAuthProtocol
  clientOptions

exports.getFileName = (withTimestamp, prefix, ts = (new Date()).getTime()) ->
  if withTimestamp
    "#{prefix}_#{ts}.csv"
  else
    "#{prefix}.csv"
