_ = require 'underscore'
Q = require 'q'
Csv = require 'csv'

class CsvMapping

  mapOrders: (template, orders) ->
    deferred = Q.defer()

    @analyseTemplate(template)
    .then (header) =>
      csv = [header]
      _.each orders, (order) =>
        csv.push @mapOrder(order, header)

      Csv().from(csv)
      .to.string (asString) ->
        deferred.resolve asString

    .fail (err) ->
      deferred.reject err
    .done()

    deferred.promise

  mapOrder: (order, header) ->
    row = []
    _.each header, (head, index) ->
      row[index] = order[head]

    row

  analyseTemplate: (template) ->
    deferred = Q.defer()
    @parse(template)
    .then (header) ->
      # TODO: analyse!
      deferred.resolve header

    .done()

    deferred.promise

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