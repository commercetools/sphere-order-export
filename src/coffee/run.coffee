fs = require 'q-io/fs'
Q = require 'q'
_ = require 'underscore'
tmp = require 'tmp'
{ExtendedLogger, ProjectCredentialsConfig, Sftp, Qutils, TaskQueue} = require 'sphere-node-utils'
package_json = require '../package.json'
OrderExport = require '../lib/orderexport'

argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .describe('projectKey', 'your SPHERE.IO project-key')
  .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
  .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
  .describe('fetchHours', 'Number of hours to fetch modified orders')
  .describe('standardShippingMethod', 'Allows to define the fallback shipping method name of order has none')
  .describe('useExportTmpDir', 'whether to use a tmp folder to store resulting XML files in or not (if no, files will be created under \'./exports\')')
  .describe('sftpCredentials', 'the path to a JSON file where to read the credentials from')
  .describe('sftpHost', 'the SFTP host (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpUsername', 'the SFTP username (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpPassword', 'the SFTP password (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpTarget', 'path in the SFTP server to where to move the worked files')
  .describe('logLevel', 'log level for file logging')
  .describe('logDir', 'directory to store logs')
  .describe('logSilent', 'use console to print messages')
  .describe('timeout', 'Set timeout for requests')
  .default('fetchHours', 0) # by default don't restrict on modifications
  .default('standardShippingMethod', 'None')
  .default('useExportTmpDir', true)
  .default('logLevel', 'info')
  .default('logDir', '.')
  .default('logSilent', false)
  .default('timeout', 60000)
  .demand(['projectKey'])
  .argv

logOptions =
  name: "#{package_json.name}-#{package_json.version}"
  streams: [
    { level: 'error', stream: process.stderr }
    { level: argv.logLevel, path: "#{argv.logDir}/sphere-order-xml-import.log" }
  ]
logOptions.silent = argv.logSilent if argv.logSilent
logger = new ExtendedLogger
  additionalFields:
    project_key: argv.projectKey
  logConfig: logOptions
if argv.logSilent
  logger.bunyanLogger.trace = -> # noop
  logger.bunyanLogger.debug = -> # noop

process.on 'SIGUSR2', -> logger.reopenFileStreams()
process.on 'exit', => process.exit(@exitCode)

tmp.setGracefulCleanup()
createTmpDir = ->
  d = Q.defer()
  # unsafeCleanup: recursively removes the created temporary directory, even when it's not empty
  tmp.dir {unsafeCleanup: true}, (err, path) ->
    if err
      d.reject err
    else
      d.resolve path
  d.promise

ensureExportDir = ->
  if "#{argv.useExportTmpDir}" is 'true'
    createTmpDir()
  else
    exportsPath = "#{__dirname}/../exports"
    fs.exists(exportsPath)
    .then (exists) ->
      if exists
        Q(exportsPath)
      else
        fs.makeDirectory(exportsPath)
        .then -> Q(exportsPath)
    .fail (err) -> Q.reject(err)

readJsonFromPath = (path) ->
  return Q({}) unless path
  fs.read(path).then (content) ->
    Q JSON.parse(content)

ProjectCredentialsConfig.create()
.then (credentials) =>
  options =
    config: credentials.enrichCredentials
      project_key: argv.projectKey
      client_id: argv.clientId
      client_secret: argv.clientSecret
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
    logConfig:
      logger: logger.bunyanLogger

  orderExport = new OrderExport options
  orderExport.standardShippingMethod = argv.standardShippingMethod
  client = orderExport.client

  tq = new TaskQueue

  ensureExportDir()
  .then (outputDir) =>
    logger.debug "Created output dir at #{outputDir}"
    @outputDir = outputDir
    client.orders.last("#{argv.fetchHours}h").perPage(0).fetch()
  .then (result) ->
    orderExport.processOrders(result.body.results)
  .then (xmlOrders) =>
    logger.info "Storing #{_.size xmlOrders} file(s) to '#{@outputDir}'."
    @orderReferences = []
    Q.all _.map xmlOrders, (entry) =>
      tq.addTask =>
        content = entry.xml.end(pretty: true, indent: '  ', newline: "\n")
        fileName = "#{entry.id}.xml"
        @orderReferences.push name: fileName, entry: entry
        fs.write "#{@outputDir}/#{fileName}", content
  .then =>
    {sftpCredentials, sftpHost, sftpUsername, sftpPassword} = argv
    if sftpCredentials or (sftpHost and sftpUsername and sftpPassword)

      readJsonFromPath(sftpCredentials)
      .then (credentials) =>
        projectSftpCredentials = credentials[argv.projectKey] or {}
        {host, username, password, sftpTarget} = _.defaults projectSftpCredentials,
          host: sftpHost
          username: sftpUsername
          password: sftpPassword
          sftpTarget: argv.sftpTarget

        throw new Error 'Missing sftp host' unless host
        throw new Error 'Missing sftp username' unless username
        throw new Error 'Missing sftp password' unless password

        sftpClient = new Sftp
          host: host
          username: username
          password: password
          logger: logger

        sftpClient.openSftp()
        .then (sftp) =>
          fs.list(@outputDir)
          .then (files) ->
            logger.info "About to upload #{_.size files} file(s) from #{@outputDir} to #{sftpTarget}"
            Qutils.processList files, (filename) ->
              logger.debug "Uploading #{@outputDir}/#{filename}"
              sftpClient.safePutFile(sftp, "#{@outputDir}/#{filename}", "#{sftpTarget}/#{filename}")
              .then ->
                xml = _.find @orderReferences, (r) -> r.name is filename
                if xml
                  logger.debug "About to sync order #{filename}"
                  orderExport.syncOrder xml.entry, filename
                else
                  logger.warn "Not able to create syncInfo for #{filename} as xml for that file was not found"
                  Q()
            .then ->
              logger.info "Successfully uploaded #{_.size files} file(s)"
              sftpClient.close(sftp)
              Q()
          .fail (err) ->
            sftpClient.close(sftp)
            Q.reject err
      .fail (err) =>
        logger.error err, "Problems on getting sftp credentials from config files for project #{argv.projectKey}."
        # process.exit(1)
        @exitCode = 1
    else
      Q()
  .then =>
    logger.info 'Orders export complete'
    # process.exit(0)
    @exitCode = 0
  .fail (error) =>
    logger.error error, 'Oops, something went wrong!'
    # process.exit(1)
    @exitCode = 1
  .done()

.fail (err) =>
  logger.error err, 'Problems on getting client credentials from config files.'
  # process.exit(1)
  @exitCode = 1
.done()