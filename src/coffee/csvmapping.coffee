_ = require 'underscore'
Q = require 'q'
Csv = require 'csv'
access = require('safe-access')

class CsvMapping

  mapOrders: (template, orders) ->
    deferred = Q.defer()

    @analyseTemplate(template)
    .then ([header, mappings]) =>
      rows = _.map orders, (order) =>
        @mapOrder(order, mappings)

      Csv().from([header].concat rows)
      .to.string (asString) ->
        deferred.resolve asString

      .on 'error', (error) ->
        deferred.reject error

    deferred.promise

  mapOrder: (order, mappings) ->
    _.map mappings, (mapping, index) ->
      value = access order, mapping[0]
      if _.size(mapping) is 2 and _.isFunction mapping[1]
        mapping[1].call undefined, value
      else
        value

  analyseTemplate: (template) ->
    @parse(template)
    .then (header) =>
      mappings = _.map header, (entry) =>
        @mapHeaderToAccessor(entry)
      Q [header, mappings]

  mapHeaderToAccessor: (entry) ->
    switch entry
      when 'totalNet', 'totalGross' then ["taxedPrice.#{entry}", formatPrice]
      when 'totalPrice' then [entry, formatPrice]
      else [entry]

  formatPrice = (price) ->
    "#{price.currencyCode} #{price.centAmount}"

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