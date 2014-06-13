OrderExport = require '../lib/orderexport'
Config = require '../config'

describe '#mapOrder', ->
  beforeEach ->
    @orderExport = new OrderExport Config

  it 'export base attributes', ->
    template =
      """
      id
      """

    orders =
      [{
        id: 'abc'
        orderNumber: '10001'
        version: 1
        lineItems: [
          { sku: 'mySKU' }
        ]
      },{
        id: 'bcd'
        orderNumber: '10002'
        version: 1
      }]
 
    expectedCSV =
      """
      id
      abc
      """

    csv = @orderExport.toCSV template, orders
    expect(csv).toBe expectedCSV
