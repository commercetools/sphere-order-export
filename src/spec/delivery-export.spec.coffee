_ = require 'underscore'
tmp = require 'tmp'
DeliveryExport = require '../lib/delivery-export'
Config = require '../config'
utils = require '../lib/utils'

tmp.setGracefulCleanup()
logDir = tmp.dirSync()

logger = utils.getLogger({logDir: logDir.name}, 'delivery-export-test')

describe 'DeliveryExport', ->

  beforeEach ->
    @deliveryExport = new DeliveryExport({client: Config}, logger)

  it 'should have default options', ->
    expect(@deliveryExport.logger).toEqual(logger)
    expect(@deliveryExport.stats).toEqual
      loadedOrders: 0
      exportedDeliveries: 0
      exportedRows: 0

    # should have default stats
    expect(@deliveryExport.options.export).toEqual
      where: ''
      perPage: 500

  it '#_getCsvHeader should return a CSV header', ->
    expect(@deliveryExport._getCsvHeader()).toBe [
        'orderNumber',
        'delivery.id',
        '_itemGroupId',
        'item.id',
        'item.quantity',
        'parcel.id',
        'parcel.length',
        'parcel.height',
        'parcel.width',
        'parcel.weight',
        'parcel.trackingId',
        'parcel.carrier',
        'parcel.provider',
        'parcel.providerTransaction',
        'parcel.isReturn'
      ].join(',')

  it '#_castRowsToCsv should return a CSV string without header', (done) ->
    expectedResult = '123,abcd,0\n456,efgh,1'
    rows = [
      {
        aa: 123,
        bb: 'abcd',
        cc: 0
      },
      {
        aa: 456,
        bb: 'efgh',
        cc: 1
      }
    ]

    @deliveryExport._castRowsToCsv rows
    .then (csv) ->
      expect(csv).toEqual expectedResult
      done()
    .catch (e) -> done e

  it '#_connectItemWithParcel should merge parcel with an item', ->
    item =
      orderNumber: '1234'
      'delivery.id': '1111'
      'item.id': '333'
      'item.quantity': '100'
      'parcel.id': '102222220' # will be overwritten

    parcel =
       id: '1'
       trackingData:
         trackingId: '123456789'
         carrier: 'TEST'
         provider: 'provider 1'
         providerTransaction: 'provider transaction 1'
         isReturn: false
       measurements:
         lengthInMillimeter: 100
         heightInMillimeter: 200
         widthInMillimeter: 300
         weightInGram: 500

    expectedResult =
      orderNumber: '1234'
      'delivery.id': '1111'
      'item.id': '333'
      'item.quantity': '100'
      'parcel.id': '1'
      'parcel.length': 100
      'parcel.height': 200
      'parcel.width': 300
      'parcel.weight': 500
      'parcel.trackingId': '123456789'
      'parcel.carrier': 'TEST'
      'parcel.provider': 'provider 1'
      'parcel.providerTransaction': 'provider transaction 1'
      'parcel.isReturn': 0

    res = @deliveryExport._connectItemWithParcel item, parcel
    expect(res).toEqual expectedResult

  it '#_mapDeliveriesToRows should serialize deliveries', ->
    orderNumber = '123'
    deliveries = [{
      id: 'deliveryId',
      createdAt: '2017-06-09T19:33:22.230Z',
      items: [{
        id: 'item1_id',
        quantity: 1
      }, {
        id: 'item2_id',
        quantity: 20
      }],
      parcels: [{
        id: 'parcelId',
        createdAt: '2017-06-09T19:33:22.230Z',
        trackingData: {
          trackingId: '111',
          carrier: 'dhl',
          isReturn: false
        }
      }]
    }]

    res = @deliveryExport._mapDeliveriesToRows orderNumber, deliveries
    expect(res).toEqual [{
      orderNumber: '123',
      'delivery.id': 'deliveryId',
      _itemGroupId: 0,
      'item.id': 'item1_id',
      'item.quantity': 1,
      'parcel.id': 'parcelId',
      'parcel.length': '',
      'parcel.height': '',
      'parcel.width': '',
      'parcel.weight': '',
      'parcel.trackingId': '111',
      'parcel.carrier': 'dhl',
      'parcel.provider': '',
      'parcel.providerTransaction': '',
      'parcel.isReturn': 0
    }, {
      orderNumber: '123',
      'delivery.id': 'deliveryId',
      _itemGroupId: 1,
      'item.id': 'item2_id',
      'item.quantity': 20,
      'parcel.id': '',
      'parcel.length': '',
      'parcel.height': '',
      'parcel.width': '',
      'parcel.weight': '',
      'parcel.trackingId': '',
      'parcel.carrier': '',
      'parcel.provider': '',
      'parcel.providerTransaction': '',
      'parcel.isReturn': ''
    }]

  it '#_mapDeliveriesToRows should serialize deliveries with multiple parcels', ->
    orderNumber = '123'
    deliveries = [{
      id: 'deliveryId',
      createdAt: '2017-06-09T19:33:22.230Z',
      items: [{
        id: 'item1_id',
        quantity: 1
      }],
      parcels: [{
        id: 'parcelId',
        createdAt: '2017-06-09T19:33:22.230Z',
        trackingData: {
          trackingId: '111',
          carrier: 'dhl',
          isReturn: false
        }
      }, {
        id: 'parcelId_2',
        trackingData: {
          trackingId: '222',
          carrier: 'dpp',
          isReturn: true
        }
      }]
    }]

    res = @deliveryExport._mapDeliveriesToRows orderNumber, deliveries
    expect(res).toEqual [{
      orderNumber: '123',
      'delivery.id': 'deliveryId',
      _itemGroupId: 0,
      'item.id': 'item1_id',
      'item.quantity': 1,
      'parcel.id': 'parcelId',
      'parcel.length': '',
      'parcel.height': '',
      'parcel.width': '',
      'parcel.weight': '',
      'parcel.trackingId': '111',
      'parcel.carrier': 'dhl',
      'parcel.provider': '',
      'parcel.providerTransaction': '',
      'parcel.isReturn': 0
    }, {
      orderNumber: '123',
      'delivery.id': 'deliveryId',
      _itemGroupId: 0,
      'item.id': 'item1_id',
      'item.quantity': 1,
      'parcel.id': 'parcelId_2',
      'parcel.length': '',
      'parcel.height': '',
      'parcel.width': '',
      'parcel.weight': '',
      'parcel.trackingId': '222',
      'parcel.carrier': 'dpp',
      'parcel.provider': '',
      'parcel.providerTransaction': '',
      'parcel.isReturn': 1
    }]

