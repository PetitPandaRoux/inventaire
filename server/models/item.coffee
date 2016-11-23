CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'

module.exports = Item = {}

Item.tests = tests = require './tests/item'
Item.attributes = attributes = require './attributes/item'
{ solveConstraint } = require('./helpers')(attributes)

Item.create = (userId, item)->
  _.types arguments, ['string', 'object']
  # we want to get couchdb sequential id
  # so we need to let _id blank
  item = _.omit item, '_id'

  { title, entity, pictures } = item
  tests.pass 'title', title
  tests.pass 'entity', entity

  tests.pass 'userId', userId
  item.owner = userId

  item.pictures = pictures or= []
  tests.pass 'pictures', pictures

  item.created = Date.now()
  item.listing = solveConstraint item, 'listing'
  item.transaction = solveConstraint item, 'transaction'
  return item

passAttrTest = (item, attr)->
  if item[attr]? then tests.pass attr, item[attr]

Item.update = (userId, updateAttributesData, doc)->
  unless doc?.owner is userId
    throw new Error "user isnt doc.owner: #{userId} / #{doc.owner}"

  nonUpdatedAttribute = Object.keys _.omit(updateAttributesData, attributes.known)
  if nonUpdatedAttribute.length > 0
    throw error_.new "invalid attribute(s): #{nonUpdatedAttribute}", 400

  # filter-out non-updatable attributes
  newData = _.pick updateAttributesData, attributes.updatable

  for attr in attributes.updatable
    passAttrTest updateAttributesData, attr

  _.extend doc, newData
  doc.updated = Date.now()
  return doc

Item.changeOwner = (transacDoc, item)->
  _.types arguments, 'objects...'
  _.log arguments, 'changeOwner'

  item = _.omit item, attributes.reset
  _.log item, 'item without reset attributes'

  { _id: transacId, owner, requester } = transacDoc

  unless item.owner is owner
    throw new Error "owner doesn't match item owner"

  item.history or= []
  item.history.push
    transaction: transacId
    previousOwner: owner
    timestamp: Date.now()

  _.log item.history, 'updated history'

  _.extend item,
    owner: requester
    # default values
    transaction: 'inventorying'
    listing: 'private'
    updated: Date.now()

Item.allowTransaction = (item)->
  item.transaction in attributes.allowTransaction

Item.updateEntityAfterEntityMerge = (fromUri, toUri, item)->
  unless item.entity is fromUri
    throw error_.new "wrong entity uri: expected #{fromUri}, got #{item.entity}", 500

  _.log item, 'item before entity merge'

  item.entity = toUri
  # Keeping track of previous entity URI in case a rollback is needed
  item.previousEntity or= []
  item.previousEntity.unshift fromUri

  return _.log item, 'item after entity merge'
