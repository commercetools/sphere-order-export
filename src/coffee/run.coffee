path = require 'path'
_ = require 'underscore'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
tmp = Promise.promisifyAll require('tmp')
{ExtendedLogger, ProjectCredentialsConfig, Sftp} = require 'sphere-node-utils'
package_json = require '../package.json'
OrderExport = require './orderexport'
csv = require 'csv-parser'

CHANNEL_KEY = 'OrderXmlFileExport'

argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .describe('projectKey', 'your SPHERE.IO project-key')
  .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
  .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
  .describe('accessToken', 'an OAuth access token for the SPHERE.IO API')
  .describe('sphereHost', 'SPHERE.IO API host to connect to')
  .describe('sphereProtocol', 'SPHERE.IO API protocol to connect to')
  .describe('sphereAuthHost', 'SPHERE.IO OAuth host to connect to')
  .describe('sphereAuthProtocol', 'SPHERE.IO OAuth protocol to connect to')
  .describe('fetchHours', 'Number of hours to fetch modified orders')
  .describe('perPage', 'Number of orders to be fetched per page')
  .describe('standardShippingMethod', 'Allows to define the fallback shipping method name if order has none')
  .describe('exportUnsyncedOnly', 'whether only unsynced orders will be exported or not')
  .describe('targetDir', 'the folder where exported files are saved')
  .describe('useExportTmpDir', 'whether to use a system tmp folder to store exported files')
  .describe('csvTemplate', 'CSV template to define the structure of the export')
  .describe('createSyncActions', 'upload syncInfo update actions for orders exported (only supports sftp upload')
  .describe('fileWithTimestamp', 'whether exported file should contain a timestamp')
  .describe('sftpCredentials', 'the path to a JSON file where to read the credentials from')
  .describe('sftpHost', 'the SFTP host (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpUsername', 'the SFTP username (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpPassword', 'the SFTP password (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpTarget', 'path in the SFTP server to where to move the worked files')
  .describe('sftpContinueOnProblems', 'ignore errors when processing a file and continue with the next one')
  .describe('logLevel', 'log level for file logging')
  .describe('logDir', 'directory to store logs')
  .describe('logSilent', 'use console to print messages')
  .describe('timeout', 'Set timeout for requests')
  .describe('exportCSVAsStream', 'Exports CSV as stream (to use for performance reasons)')
  .default('fetchHours', 48) # let's keep it limited to 48h
  .default('perPage', 100)
  .default('standardShippingMethod', 'None')
  .default('exportUnsyncedOnly', true)
  .default('targetDir', path.join(__dirname,'../exports'))
  .default('useExportTmpDir', false)
  .default('fileWithTimestamp', false)
  .default('logLevel', 'info')
  .default('logDir', '.')
  .default('createSyncActions', false)
  .default('logSilent', false)
  .default('timeout', 60000)
  .default('sftpContinueOnProblems', false)
  .default('exportCSVAsStream', false)
  .demand(['projectKey'])
  .argv

logOptions =
  name: "#{package_json.name}-#{package_json.version}"
  streams: [
    { level: 'error', stream: process.stderr }
    { level: argv.logLevel, path: "#{argv.logDir}/#{package_json.name}.log" }
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

fsExistsAsync = (path) ->
  new Promise (resolve, reject) ->
    fs.exists path, (exists) ->
      if exists
        resolve(true)
      else
        resolve(false)

ensureExportDir = ->
  if "#{argv.useExportTmpDir}" is 'true'
    # unsafeCleanup: recursively removes the created temporary directory, even when it's not empty
    tmp.dirAsync {unsafeCleanup: true}
  else
    exportsPath = argv.targetDir
    fsExistsAsync(exportsPath)
    .then (exists) ->
      if exists
        Promise.resolve(exportsPath)
      else
        fs.mkdirAsync(exportsPath)
        .then -> Promise.resolve(exportsPath)

readJsonFromPath = (path) ->
  return Promise.resolve({}) unless path
  fs.readFileAsync(path, {encoding: 'utf-8'}).then (content) ->
    Promise.resolve JSON.parse(content)

exportCSVAsStream = (csvFile, orderExport) ->
  new Promise (resolve, reject) ->
    output = fs.createWriteStream csvFile, {encoding: 'utf-8'}
    output.on 'error', (error) -> reject error
    output.on 'finish', -> resolve()
    orderExport.runCSVAndStreamToFile (data) =>
      process.stdout.write('.')
      output.write data
      Promise.resolve()
    .then () ->
      process.stdout.write('\n')
      output.end()
    .catch (e) -> reject(e)

ensureCredentials = (argv) ->
  if argv.accessToken
    Promise.resolve
      config:
        project_key: argv.projectKey
      access_token: argv.accessToken
  else
    ProjectCredentialsConfig.create()
    .then (credentials) ->
      Promise.resolve
        config: credentials.enrichCredentials
          project_key: argv.projectKey
          client_id: argv.clientId
          client_secret: argv.clientSecret

createSyncOrders = (fileName) ->
  logger.debug "Creating order objects with sync Information"
  new Promise (resolve, reject) ->
    orders = []
    fs.createReadStream(fileName)
      .pipe(csv())
      .on('data', (data) ->
        order =
          orderNumber: data.orderNumber
          syncInfo: [{
            externalId: fileName
            channel: CHANNEL_KEY
          }]
        orders.push(order)
      )
      .on('end', () ->
        logger.info "SyncInfo generated #{JSON.stringify(orders)}"
        resolve(orders)
      )
      .on 'error', (err) ->
        reject(err)


ensureCredentials(argv)
.then (credentials) =>
  clientOptions = _.extend credentials,
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
  clientOptions.host = argv.sphereHost if argv.sphereHost
  clientOptions.protocol = argv.sphereProtocol if argv.sphereProtocol
  if argv.sphereAuthHost
    clientOptions.oauth_host = argv.sphereAuthHost
    clientOptions.rejectUnauthorized = false
  clientOptions.oauth_protocol = argv.sphereAuthProtocol if argv.sphereAuthProtocol

  exportType = if argv.csvTemplate then 'csv' else 'xml'

  orderExport = new OrderExport
    client: clientOptions
    export:
      fetchHours: argv.fetchHours
      perPage: argv.perPage
      standardShippingMethod: argv.standardShippingMethod
      exportType: exportType
      exportUnsyncedOnly: argv.exportUnsyncedOnly
      csvTemplate: argv.csvTemplate

  ensureExportDir()
  .then (outputDir) =>
    logger.debug "Created output dir at #{outputDir}"
    @outputDir = outputDir
    if argv.exportCSVAsStream
      logger.info "Exporting orders as stream."
      if argv.fileWithTimestamp
        ts = (new Date()).getTime()
        fileName = "orders_#{ts}.csv"
      else
        fileName = 'orders.csv'
      csvFile = argv.csvFile or "#{@outputDir}/#{fileName}"
      exportCSVAsStream(csvFile, orderExport)

    else
      orderExport.run()
      .then (data) =>
        # TODO: xml export
        # - one file for all (default)
        # - one file for each order
        @orderReferences = []
        ts = (new Date()).getTime()
        if exportType.toLowerCase() is 'csv'
          if argv.fileWithTimestamp
            fileName = "orders_#{ts}.csv"
          else
            fileName = 'orders.csv'
          csvFile = argv.csvFile or "#{@outputDir}/#{fileName}"
          logger.info "Storing CSV export to '#{csvFile}'."
          @orderReferences.push fileName: csvFile, entry: data
          fs.writeFileAsync csvFile, data
        else
          logger.info "Storing #{_.size data} file(s) to '#{@outputDir}'."
          Promise.map data, (entry) =>
            content = entry.xml.end(pretty: true, indent: '  ', newline: '\n')
            if argv.fileWithTimestamp
              fileName = "#{entry.id}_#{ts}.xml"
            else
              fileName = "#{entry.id}.xml"
            @orderReferences.push name: fileName, entry: entry
            fs.writeFileAsync "#{@outputDir}/#{fileName}", content
          , {concurrency: 10}
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
          fs.readdirAsync(@outputDir)
          .then (files) =>
            logger.info "About to upload #{_.size files} file(s) from #{@outputDir} to #{sftpTarget}"
            filesSkipped = 0
            Promise.map files, (filename) =>
              logger.debug "Uploading #{@outputDir}/#{filename}"
              sftpClient.safePutFile(sftp, "#{@outputDir}/#{filename}", "#{sftpTarget}/#{filename}")
              .then =>
                if exportType.toLowerCase() is 'csv' and argv.createSyncActions
                  createSyncOrders(@orderReferences[0].fileName)
                    .then (orders) =>
                      orderJsonFile = "tobeSyncOrders.json" # Can be renamed??
                      fs.writeFileAsync("#{@outputDir}/#{orderJsonFile}", JSON.stringify(orders,null,2)).then =>
                        logger.debug "Uploading #{@outputDir}/#{orderJsonFile}"
                        sftpClient.safePutFile(sftp, "#{@outputDir}/#{orderJsonFile}", "#{sftpTarget}/#{orderJsonFile}")
                else
                  xml = _.find @orderReferences, (r) -> r.name is filename
                  if xml
                    logger.debug "About to sync order #{filename}"
                    orderExport.syncOrder xml.entry, filename
                  else
                    logger.warn "Not able to create syncInfo for #{filename} as xml for that file was not found"
                    Promise.resolve()
              .catch (err) ->
                if argv.sftpContinueOnProblems
                  filesSkipped++
                  logger.warn err, "There was an error processing the file #{file}, skipping and continue"
                  Promise.resolve()
                else
                  Promise.reject err
            , {concurrency: 1}
            .then ->
              totFiles = _.size(files)
              if totFiles > 0
                logger.info "Export to SFTP successfully finished: #{totFiles - filesSkipped} out of #{totFiles} files were processed"
              else
                logger.info "Export successfully finished: there were no new files to be processed"
              sftpClient.close(sftp)
              Promise.resolve()
          .finally -> sftpClient.close(sftp)
        .catch (err) =>
          logger.error err, 'There was an error uploading the files to SFTP'
          @exitCode = 1
      .catch (err) =>
        logger.error err, "Problems on getting sftp credentials from config files for project #{argv.projectKey}."
        @exitCode = 1
    else
      Promise.resolve() # no sftp
  .then =>
    logger.info 'Orders export complete'
    @exitCode = 0
  .catch (error) =>
    logger.error error, 'Oops, something went wrong!'
    @exitCode = 1
  .done()
.catch (err) =>
  logger.error err, 'Problems on getting client credentials from config files.'
  @exitCode = 1
.done()
