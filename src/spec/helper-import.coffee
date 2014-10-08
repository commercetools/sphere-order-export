_ = require 'underscore'
_.mixin require('underscore-mixins')
{SphereClient} = require 'sphere-node-sdk'
Config = require '../config'
SpecHelper = require './helper'

CHANNEL_KEY = 'OrderXmlFileExport'
CHANNEL_ROLE = 'OrderExport'
CONTAINER_PAYMENT = 'checkoutInfo'

client = new SphereClient Config

client.channels.ensure(CHANNEL_KEY, CHANNEL_ROLE)
.then ->
  # get a tax category required for setting up shippingInfo
  #   (simply returning first found)
  client.taxCategories.save SpecHelper.taxCategoryMock()
.then (result) =>
  @taxCategory = result.body
  client.zones.save SpecHelper.zoneMock()
.then (result) =>
  zone = result.body
  client.shippingMethods.save SpecHelper.shippingMethodMock(zone, @taxCategory)
.then (result) =>
  @shippingMethod = result.body
  client.productTypes.save SpecHelper.productTypeMock()
.then (result) =>
  productType = result.body
  client.products.save SpecHelper.productMock(productType)
.then (result) =>
  @product = result.body
  client.customers.save SpecHelper.customerMock()
.then (result) =>
  @customer = result.body.customer
  client.orders.import SpecHelper.orderMock(@shippingMethod, @product, @taxCategory, @customer)
.then (result) =>
  @order = result.body
  client.customObjects.save SpecHelper.orderPaymentInfo(CONTAINER_PAYMENT, @order.id)
.then -> console.log 'Order imported'
.catch (err) -> console.error _.prettify err
