_ = require 'underscore'
_.mixin require('underscore-mixins')
Mapping = require '../lib/mapping-utils/csv'
testOrders = require '../data/orders'

template = 'id,orderNumber,totalPrice,lineItems.id,lineItems.productId,billingAddress.firstName'

describe 'CsvMapping', ->
  it '#_mapOrder should remove redundant info', (done) ->
    mapping = new Mapping
    mapping ._analyseTemplate template
    .then ([header, mappings]) ->
      rows = mapping._mapOrder(testOrders[0], mappings)
      expect(rows.length).toBe 3
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', '', '', 'John' ],
        [ 'abc',
          '10001',
          undefined,
          'LineItemId-1-1',
          'ProductId-1-1',
          undefined ],
        [ 'abc',
          '10001',
          undefined,
          'LineItemId-1-2',
          'ProductId-1-2',
          undefined ]
      ]
      done()

  it '#_mapOrder should fill all rows', (done) ->
    mapping = new Mapping fillAllRows: true
    mapping ._analyseTemplate template
    .then ([header, mappings]) ->
      rows = mapping._mapOrder(testOrders[0], mappings)
      expect(rows.length).toBe 3
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', '', '', 'John' ],
        [ 'abc',
          '10001',
          'USD 5950',
          'LineItemId-1-1',
          'ProductId-1-1',
          'John' ],
        [ 'abc',
          '10001',
          'USD 5950',
          'LineItemId-1-2',
          'ProductId-1-2',
          'John' ]
      ]
      done()

  it '#_mapOrder should return order even when lineItems are missing', (done) ->
    mapping = new Mapping fillAllRows: true
    mapping ._analyseTemplate template
    .then ([header, mappings]) ->
      order = _.deepClone(testOrders[0])
      order.lineItems = []

      rows = mapping._mapOrder(order, mappings)
      expect(rows.length).toBe 1
      expect(rows).toEqual [
        [ 'abc', '10001', 'USD 5950', '', '', 'John' ],
      ]
      done()

