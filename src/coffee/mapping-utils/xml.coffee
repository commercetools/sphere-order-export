_ = require 'underscore'
builder = require 'xmlbuilder'

class XmlMapping

  constructor: (options = {}) ->
    @standardShippingMethod = options.standardShippingMethod or 'None'

  mapOrders: -> # TODO: allow to map all orders into one xml

  mapOrder: (order, paymentInfo, customer) ->
    xml = builder.create('order',
      { 'version': '1.0', 'encoding': 'UTF-8', 'standalone': true })
    xml.e('xsdVersion').t('0.9')

    attribs = [ 'id', 'orderNumber', 'version', 'createdAt', 'lastModifiedAt',
                'country',
                'customerId', 'customerEmail']

    for attr in attribs
      @_add(xml, order, attr)

    xml.e('customerNumber')
      .t(customer.customerNumber) if customer?.customerNumber

    if customer?.externalId
      xml.e('externalCustomerId')
        .t(customer.externalId)

    states = [ 'orderState', 'shipmentState', 'paymentState' ]
    for attr in states
      @_add(xml, order, attr, attr, 'Pending')

    if order.taxedPrice
      price = order.taxedPrice
      xPrice = xml.e('taxedPrice')
      @_money(xPrice, price, 'totalNet')
      @_money(xPrice, price, 'totalGross')

      for tax in price.taxPortions
        xT = xPrice.e('taxPortions')
        xT.e('rate').t(tax.rate)
        @_money(xT, tax, 'amount')

    if order.shippingAddress
      @_address(xml.e('shippingAddress'), order.shippingAddress)

    if order.billingAddress
      @_address(xml.e('billingAddress'), order.billingAddress)

    @_customerGroup(xml, order)

    if paymentInfo?
      xPi = xml.e('paymentInfo')
      @_add(xPi, paymentInfo.value, 'paymentMethod') if paymentInfo.value.paymentMethod
      xPi.e('paymentID').t(paymentInfo.value.paymentTransaction).up() if paymentInfo.value.paymentTransaction

    si = order.shippingInfo
    xSi = xml.e('shippingInfo')
    if order.shippingInfo?
      @_add(xSi, si, 'shippingMethodName')
      @_add(xSi, si, 'trackingData')
      @_money(xSi, si, 'price')
      @_taxRate(xSi, si)
    else
      xSi.e('shippingMethodName').t(@standardShippingMethod).up()

    if order.lineItems
      for lineItem in order.lineItems
        xLi = xml.e('lineItems')
        @_add(xLi, lineItem, 'id')
        @_add(xLi, lineItem, 'productId')
        @_add(xLi, lineItem.name, 'de', 'name')

        variant = lineItem.variant
        xVariant = xLi.e('variant')
        @_add(xVariant, variant, 'id')
        @_add(xVariant, variant, 'sku')
        if variant.prices
          for price in variant.prices
            @_priceElem(xVariant.e('prices'), price)

        if variant.attributes
          for attr in variant.attributes
            @_attributes(xVariant.e('attributes'), attr)

        # Adds sku again directly to the lineItem
        @_add(xLi, variant, 'sku')

        @_price(xLi, lineItem)
        @_add(xLi, lineItem, 'quantity')

        # Adds lineItem price
        @_lineItemPrice xLi, lineItem.price.value.centAmount, lineItem.quantity,
          lineItem.price.value.currencyCode

        @_taxRate(xLi, lineItem)

    if order.customLineItems
      for customLineItem in order.customLineItems
        @_customLineItem(xml.e('customLineItems'), customLineItem)

    xml

  _customLineItem: (xml, elem) ->
    @_add(xml, elem, 'id')
    @_add(xml, elem.name, 'de', 'name')
    @_money(xml, elem, 'money')
    @_add(xml, elem, 'slug')
    @_add(xml, elem, 'quantity')
    @_lineItemPrice xml, elem.money.centAmount, elem.quantity,
      elem.money.currencyCode
    @_taxRate(xml, elem)

  _attributes: (xml, elem) ->
    val = elem.value
    if _.has(val, 'key') and _.has(val, 'label')
      val = val.key
    if _.has(val, 'centAmount') and _.has(val, 'currencyCode')
      val = "#{val.currencyCode} #{val.centAmount}"
    xml.e('name').t(elem.name).up()
      .e('value').t(val)

  _money: (xml, elem, name) ->
    xml.e(name)
      .e('currencyCode').t(elem[name].currencyCode).up()
      .e('centAmount').t(elem[name].centAmount)

  _price: (xml, elem, name = 'price') ->
    @_priceElem(xml.e(name), elem.price)

  _priceElem: (xP, p) ->
    @_money(xP, p, 'value')
    @_add(xP, p, 'country')
    @_customerGroup(xP, p)

  _lineItemPrice: (xml, centAmount, quantity, currencyCode) ->
    total = centAmount * quantity
    p =
      price:
        value:
          currencyCode: currencyCode
          centAmount: total
    @_price(xml, p, 'lineItemPrice')

  _taxRate: (xml, elem) ->
    tr = elem.taxRate
    xTr = xml.e('taxRate')
    attribs = [ 'id', 'name', 'amount', 'includedInPrice', 'country', 'state' ]
    for attr in attribs
      @_add(xTr, tr, attr)

  _customerGroup: (xml, elem) ->
    cg = elem.customerGroup
    if cg
      xCg = xml.e('customerGroup')
      @_add(xCg, cg, 'id')
      if cg.obj
        @_add(xCg, cg.obj, 'version')
        @_add(xCg, cg.obj, 'name')

  _address: (xml, address) ->
    attribs = [ 'id', 'title', 'salutation', 'firstName', 'lastName',
                'streetName', 'streetNumber', 'additionalStreetInfo',
                'postalCode', 'city', 'region', 'state', 'country', 'company',
                'department','building', 'apartment', 'pOBox', 'phone',
                'mobile', 'email' ]
    for attr in attribs
      @_add(xml, address, attr)

  _add: (xml, elem, attr, xAttr, fallback) ->
    xAttr = attr unless xAttr

    value = elem[attr]
    value = fallback unless value
    xml.e(xAttr).t(value).up() if value

module.exports = XmlMapping
