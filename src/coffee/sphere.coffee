request     = require "request"
querystring = require "querystring"

debug = (msg)-> console.log("DEBUG: #{msg}")

exports.login = (projectKey, clientId, clientSecret, callback, finish)->
  debug("login")

  params =
    grant_type: "client_credentials"
    scope: "manage_project:#{projectKey}"
  payload = querystring.stringify(params)

  request_options =
    uri: "https://#{clientId}:#{clientSecret}@auth.sphere.io/oauth/token"
    method: "POST"
    body: payload
    headers:
      "User-Agent": "elastic.io <-> sphere.io: order export"
      "Content-Type": "application/x-www-form-urlencoded"
      "Content-Length": payload.length
    timeout: 3000

  request request_options, (error, response, body)->
    debug("login - status: #{response.statusCode}")

    if response.statusCode is 200
      jsonBody = JSON.parse(body)
      debug("login - token: #{jsonBody.access_token}")
      callback(projectKey, jsonBody.access_token, exports.mapOrders, finish)
    else
      throw new Error("Failed to get access token - status: #{response.statusCode}")

exports.getOrders = (projectKey, accessToken, callback, finish)->
  debug("getOrders of project #{projectKey}")
  request_options =
    uri: "https://api.sphere.io/#{projectKey}/orders?expand=" + encodeURIComponent("lineItems[*].variant.prices[*].customerGroup")
    method: "GET"
    headers:
      "User-Agent": "elastic.io <-> sphere.io: order export"
      "Authorization": "Bearer " + accessToken
    timeout: 5000

  request request_options, (error, response, body)->
    debug("getOrders - status: #{response.statusCode}")

    if response.statusCode is 200
      jsonBody = JSON.parse(body)
      callback(jsonBody, finish)
    else
      throw new Error("Failed to get access token - status: #{response.statusCode}")
