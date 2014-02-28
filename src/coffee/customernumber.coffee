SphereClient = require 'sphere-node-client'
Q = require 'q'

class CustomerNumber

  UNKOWN_CUSTOMER_NUMBER = 'UNKOWN'

  constructor: (options = {}) ->
    unless options.sphere_client
      options.sphere_client = new SphereClient options
    @customerService = options.sphere_client.customers

  getCustomerNumberById: (customerId) ->
    deferred = Q.defer()
    @customerService.byId(customerId).fetch().then (customer) ->
      if customer.customerNumber
        deferred.resolve customer.customerNumber
      else
        deferred.resolve UNKOWN_CUSTOMER_NUMBER
    .fail (res) ->
      deferred.resolve UNKOWN_CUSTOMER_NUMBER
    deferred.promise

module.exports = CustomerNumber