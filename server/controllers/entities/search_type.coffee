# A search endpoint dedicated to searching entities by types
# to fit the needs of autocomplete searches
# Relies on a local ElasticSearch instance loaded with Inventaire and Wikidata entities
# See https://github.com/inventaire/entities-search-engine
# and server/controllers/entities/lib/update_search_engine

CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
responses_ = __.require 'lib', 'responses'
error_ = __.require 'lib', 'error/error'
searchType = require './lib/search_type'

indexedTypes = [ 'works', 'humans', 'series', 'genres', 'movements', 'publishers', 'collections']

module.exports = (req, res)->
  { type, search, limit } = req.query

  _.info [ type, search, limit ], 'entities search per type'

  unless _.isNonEmptyString search
    return error_.bundleMissingQuery req, res, 'search'

  unless _.isNonEmptyString type
    return error_.bundleMissingQuery req, res, 'type'

  unless type in indexedTypes
    return error_.bundleInvalid req, res, 'type', type

  limit or= '20'

  unless _.isPositiveIntegerString limit
    return error_.bundleInvalid req, res, 'limit', limit

  limit = _.stringToInt limit

  searchType search, type, limit
  .then responses_.Send(res)
  .catch error_.Handler(req, res)
