# Entity data snapshots are a attributes of the snapshot object associated with item documents:
# - entity:title
# - entity:lang
# - entity:authors
# - entity:series
# - entity:image
# - entity:ordinal

# Their role is to keep a copy at hand of data deduced from the item's entity
# and its graph: typically, the edition the item is an instance of, the edition work,
# (or works in case of a multi-works edition), the work(s) authors, the serie(s)
# the work(s) might be part of.
# Being able to have a succint version of those data accessible from the cache
# allows to display basic data or filter large lists of items by text
# without having to query from 3 to 10+ entities per item

__ = require('config').universalPath
_ = __.require 'builders', 'utils'
{ Promise } = __.require 'lib', 'promises'
levelBase = __.require 'level', 'base'
db = levelBase.simpleSubDb 'snapshot'
refreshSnapshot = require './refresh_snapshot'
error_ = __.require 'lib', 'error/error'

module.exports =
  addToItem: (item)->
    if item.snapshot? then return Promise.resolve item

    getSnapshot item.entity
    .then (snapshot)->
      item.snapshot = snapshot
      return item

  batch: (ops)-> db.batch _.forceArray(ops)

getSnapshot = (uri, preventLoop)->
  db.get uri
  .then (snapshot)->
    if snapshot? then return snapshot

    if preventLoop is true
      throw error_.new "couldn't refresh item snapshot", 500, { uri }

    return refreshAndGet uri

refreshAndGet = (uri)->
  refreshSnapshot.fromUri uri
  .then -> getSnapshot uri, true
