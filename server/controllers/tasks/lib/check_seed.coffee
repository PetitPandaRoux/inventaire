__ = require('config').universalPath
_ = __.require 'builders', 'utils'
promises_ = __.require 'lib', 'promises'
error_ = __.require 'lib', 'error/error'

searchWikidataByText = __.require 'data', 'wikidata/search_by_text'

module.exports = (entitySeed)->
  { _id, labels, claims } = entitySeed

  lang = _.keys(labels)[0]
  title = _.values(labels)[0]

  searchWikidataByText(title)
  .then (entitySearchResult)->
    return {} unless entitySearchResult
    entitySearchResult
    .map (dominantEntity)->
      dominantUri = dominantEntity.uri
      if isSubsetOf(claims, dominantEntity.claims)
        type: "task"
        possibleDuplicates:
          [ "#{_id}": "#{dominantUri}" ]
      else
        {}

isSubsetOf = (pretender, base) ->
  _.isEqual pretender, _.pick(base, _.keys(pretender))