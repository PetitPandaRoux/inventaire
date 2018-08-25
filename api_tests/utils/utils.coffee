CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
breq = require 'bluereq'
should = require 'should'
promises_ = __.require 'lib', 'promises'
host = CONFIG.fullHost()
authEndpoint = host + '/api/auth'
{ createUser, createAdminUser, getRefreshedUser } = require '../fixtures/users'
{ request, customAuthReq } = require './request'

userPromises = {}
getUserGetter = (key, admin = false, customData)-> ()->
  unless userPromises[key]?
    createFn = if admin then createAdminUser else createUser
    userPromises[key] = createFn customData
  return getRefreshedUser userPromises[key]

module.exports = API =
  nonAuthReq: request
  customAuthReq: customAuthReq
  authReq: (args...)-> customAuthReq API.getUser(), args...
  authReqB: (args...)-> customAuthReq API.getUserB(), args...
  authReqC: (args...)-> customAuthReq API.getUserC(), args...
  adminReq: (args...)-> customAuthReq API.getAdminUser(), args...

  # Create users only if needed by the current test suite
  getUser: getUserGetter 'a'
  getUserId: -> API.getUser().get '_id'
  getUserB: getUserGetter 'b'
  getUserC: getUserGetter 'c'
  getAdminUser: getUserGetter 'admin', true
  getUserGetter: getUserGetter

_.extend API, require('../../test/utils')
