_ = require 'underscore'

uniqueId = (prefix) ->
  _.uniqueId "#{prefix}#{new Date().getTime()}_"

module.exports =

  orderPaymentInfo: (container, orderId) ->
    container: container
    key: orderId
    value:
      paymentMethod: 'Cash'
      paymentID: '7'

  shippingMethodMock: (zone, taxCategory) ->
    name: uniqueId 'S'
    zoneRates: [
      {
        zone:
          typeId: 'zone'
          id: zone.id
        shippingRates: [
          { price: {currencyCode: 'EUR', centAmount: 99}}
        ]
      }
    ]
    isDefault: false
    taxCategory:
      typeId: 'tax-category'
      id: taxCategory.id

  zoneMock: -> name: uniqueId 'Z'

  taxCategoryMock: ->
    name: uniqueId 'TC'
    rates: [
      {
        name: '5%'
        amount: 0.05
        includedInPrice: false
        country: 'DE'
        id: 'jvzkDxzl'
      }
    ]

  productTypeMock: ->
    name: uniqueId 'PT'
    description: 'bla'

  productMock: (productType) ->
    productType:
      typeId: 'product-type'
      id: productType.id
    name:
      en: uniqueId 'P'
    slug:
      en: uniqueId 'p'
    masterVariant:
      sku: uniqueId 'sku'

  orderMock: (shippingMethod, product, taxCategory, customer) ->
    id: uniqueId 'o'
    orderState: 'Open'
    paymentState: 'Pending'
    shipmentState: 'Pending'
    customerId: customer.id
    customerEmail: customer.email
    lineItems: [
      {
        productId: product.id
        name:
          de: 'foo'
        variant:
          id: 1
        taxRate:
          name: 'myTax'
          amount: 0.10
          includedInPrice: false
          country: 'DE'
        quantity: 1
        price:
          value:
            centAmount: 999
            currencyCode: 'EUR'
      }
    ]
    totalPrice:
      currencyCode: 'EUR'
      centAmount: 999
    returnInfo: []
    shippingInfo:
      shippingMethodName: 'UPS'
      price:
        currencyCode: 'EUR'
        centAmount: 99
      shippingRate:
        price:
          currencyCode: 'EUR'
          centAmount: 99
      taxRate: _.first taxCategory.rates
      taxCategory:
        typeId: 'tax-category'
        id: taxCategory.id
      shippingMethod:
        typeId: 'shipping-method'
        id: shippingMethod.id

  customerMock: ->
    firstName = uniqueId 'Heinz'
    lastName = uniqueId 'Mayer'

    customerNumber: uniqueId 'c'
    email: "#{firstName}.#{lastName}@commercetools.de"
    firstName: firstName
    lastName: lastName
    password: uniqueId 'password'
    externalId: uniqueId 'external'
