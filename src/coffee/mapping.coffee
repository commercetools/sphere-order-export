builder = require 'xmlbuilder'

class Mapping

  BASE64 = 'base64'

  _debug: (msg) ->
    console.log "DEBUG: #{msg}"

  elasticio: (msg, cfg, next, snapshot) ->
    @_debug 'process'
    @mapOrders(msg.body, next)

  mapOrders: (json, finish) ->
    orders = json.results
    @_debug "mapOrders: #{orders.length}"

    now = new Buffer(new Date().toISOString()).toString(@BASE64)
    data =
      body: {}
      attachments:
        'touch-timestamp.txt':
          content: now

    for order in orders
      xmlOrder = @mapOrder(order)
      @_debug(xmlOrder)
      fileName = "#{order.id}.xml"
      base64 = new Buffer(xmlOrder).toString(@BASE64)
      data.attachments[fileName] =
        content: base64

    finish(null, data)

  mapOrder: (order) ->
    @_debug("mapOrder: #{order.id}") if order.id

    xml = builder.create('order', { 'version': '1.0', 'encoding': 'UTF-8', 'standalone': true })
    xml.e('xsdVersion').t('0.8')

    xml.e('externalCustomerId').t('UNKNOWN').up()

    attribs = [ 'id', 'version', 'createdAt', 'lastModifiedAt', 'customerId', 'customerEmail',
                'country', 'orderState', 'shipmentState', 'paymentState' ]

    for attr in attribs
      @_add(xml, order, attr)

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

    if order.paymentInfo
      pi = order.paymentInfo
      xPi = xml.e('paymentInfo')
      @_add(xPi, pi, 'paymentMethod')
      @_add(xPi, pi, 'paymentID')

    if order.shippingInfo
      si = order.shippingInfo
      xSi = xml.e('shippingInfo')
      @_add(xSi, si, 'shippingMethodName')
      @_add(xSi, si, 'trackingData')

      @_money(xSi, si, 'price')
      @_taxRate(xSi, si)

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
        @_lineItemPrice xLi, lineItem.price.value.centAmount, lineItem.quantity, lineItem.price.value.currencyCode

        @_taxRate(xLi, lineItem)

    if order.customLineItems
      for customLineItem in order.customLineItems
        @_customLineItem(xml.e('customLineItems'), customLineItem)

    xml.end(pretty: true, indent: '  ', newline: "\n")

  _customLineItem: (xml, elem) ->
    @_add(xml, elem, 'id')
    @_add(xml, elem.name, 'de', 'name')
    @_money(xml, elem, 'money')
    @_add(xml, elem, 'slug')
    @_add(xml, elem, 'quantity')
    @_lineItemPrice xml, elem.money.centAmount, elem.quantity, elem.money.currencyCode
    @_taxRate(xml, elem)

  _attributes: (xml, elem) ->
    xml.e('name').t(elem.name).up()
      .e('value').t(elem.value)

  _money: (xml, elem, name) ->
    xml.e(name)
      .e('currencyCode').t(elem[name].currencyCode).up()
      .e('centAmount').t(elem[name].centAmount)

  _price: (xml, elem, name='price') ->
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
    attribs = [ 'id', 'title', 'salutation', 'firstName', 'lastName', 'streetName', 'streetNumber', 'additionalStreetInfo', 'postalCode',
                'city', 'region', 'state', 'country', 'company', 'department', 'building', 'apartment', 'pOBox', 'phone', 'mobile', 'email' ]
    for attr in attribs
      @_add(xml, address, attr)

  _add: (xml, elem, attr, xAttr) ->
    xAttr = attr unless xAttr

    value = elem[attr]
    xml.e(xAttr).t(value).up() if value

module.exports = Mapping