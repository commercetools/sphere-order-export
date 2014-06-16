_ = require 'underscore'
Q = require 'q'
Csv = require 'csv'

class CsvMapping

  mapOrders: (template, orders) ->
    deferred = Q.defer()

    @analyseTemplate(template)
    .then (header) =>
      rows = _.map orders, (order) =>
        @mapOrder(order, header)

      Csv().from([header].concat rows)
      .to.string (asString) ->
        deferred.resolve asString

      .on 'error', (error) ->
        deferred.reject error

    deferred.promise

  mapOrder: (order, header) ->
    _.map header, (head, index) ->
      order[head]

  _analyseTemplate: (template) ->
    deferred = Q.defer()

    @parse(template)
    .then (data) =>
      header = _.map data, (entry) =>
        @mapHeaderToAccessor(entry)
      deferred.resolve header

    deferred.promise

  analyseTemplate: (template) ->
    @parse(template)
    .then (data) =>
      Q _.map data, (entry) =>
        @mapHeaderToAccessor(entry)

  mapHeaderToAccessor: (entry) ->
    # TODO: get json path for header in order to get value
    # TODO: think about how to format values - eg. prices
    entry

  # TODO: Move to sphere-node-utils
  parse: (csvString) ->
    deferred = Q.defer()

    Csv().from.string(csvString)
    .to.array (data) ->
      deferred.resolve data[0]

    .on 'error', (error) ->
      deferred.reject error

    deferred.promise


module.exports = CsvMapping