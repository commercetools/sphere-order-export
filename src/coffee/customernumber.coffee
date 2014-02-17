SphereClient = require 'sphere-node-client'
Q = require 'q'

class CustomerNumber

  UNKOWN_CUSTOMER_NUMBER = 'UNKOWN'

  constructor: (options = {}) ->
    client = new SphereClient(options)
    @customerService = client.customers

  getCustomerNumberById: (customerId) ->
    deferred = Q.defer()
    @customerService.byId(customerId).fetch().then (customer) ->
      if customer.externalId
        deferred.resolve customer.externalId
      else
        deferred.resolve UNKOWN_CUSTOMER_NUMBER
    .fail (res) ->
      deferred.resolve UNKOWN_CUSTOMER_NUMBER
    deferred.promise


module.exports = CustomerNumber