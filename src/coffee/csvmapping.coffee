_ = require 'underscore'
Q = require 'q'
Csv = require 'csv'
access = require('safe-access')

class CsvMapping

  mapOrders: (template, orders) ->
    @analyseTemplate(template)
    .then ([header, mappings]) =>
      rows = []
      rows = rows.concat _.map orders, (order) =>
        @mapOrder(order, mappings)

      data = _.flatten rows, true
      Q @toCSV(header, data)
    
  mapOrder: (order, mappings) ->
    rows = []
    rows.push _.map mappings, (mapping) =>
      @getValue order, mapping

    if order.lineItems? and @hasLineItemHeader?
      _.each order.lineItems, (lineItem, index) =>
        rows.push _.map mappings, (mapping) =>
          if /lineItems/.test(mapping)
            lineItemMapping = [mapping[0].replace(/lineItems/, "lineItems[#{index}]"), mapping[1]]
            @getValue order, lineItemMapping
          else
            @getValue order, mapping

    rows

  getValue: (order, mapping) ->
    value = access order, mapping[0]
    if _.size(mapping) is 2 and _.isFunction mapping[1]
      mapping[1].call undefined, value
    else
      value

  analyseTemplate: (template) ->
    @parse(template)
    .then (header) =>
      mappings = _.map header, (entry) =>
        if /lineItems/.test entry
          @hasLineItemHeader = true
        @mapHeaderToAccessor(entry)
      Q [header, mappings]

  mapHeaderToAccessor: (entry) ->
    switch entry
      when 'totalNet', 'totalGross' then ["taxedPrice.#{entry}", formatMoney]
      when 'totalPrice' then [entry, formatMoney]
      when 'lineItems.price' then [entry, formatPrice]
      else [entry]

  formatPrice = (price) ->
    if price?
      countryPart = ''
      if price.country?
        countryPart = "#{price.country}-"
      customerGroupPart = ''
      if price.customerGroup?
        customerGroupPart = " #{price.customerGroup.id}"
      channelKeyPart = ''
      if price.channel?
        channelKeyPart = "##{price.channel.id}"
      "#{countryPart}#{price.value.currencyCode} #{price.value.centAmount}#{customerGroupPart}#{channelKeyPart}"

  formatMoney = (money) ->
    "#{money.currencyCode} #{money.centAmount}"

  # TODO: Move to sphere-node-utils
  parse: (csvString) ->
    deferred = Q.defer()

    Csv().from.string(csvString)
    .to.array (data) ->
      deferred.resolve data[0]

    .on 'error', (error) ->
      deferred.reject error

    deferred.promise

  toCSV: (header, data) ->
    deferred = Q.defer()
    
    Csv().from([header].concat data)
    .to.string (asString) ->
      deferred.resolve asString
    .on 'error', (error) ->
      deferred.reject error
    
    deferred.promise


module.exports = CsvMapping