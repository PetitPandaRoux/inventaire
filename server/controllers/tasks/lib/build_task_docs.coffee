__ = require('config').universalPath
_ = __.require 'builders', 'utils'
{ Promise } = __.require 'lib', 'promises'

entities_ = __.require 'controllers', 'entities/lib/entities'
searchEntityDuplicatesSuggestions = require './search_entity_duplicates_suggestions'
{ calculateRelationScore } = require './relation_score'
hasWorksLabelsOccurrence = __.require 'controllers', 'entities/lib/has_works_labels_occurrence'
{ turnIntoRedirection } = __.require 'controllers', 'entities/lib/merge_entities'
{ prefixifyInv } = __.require 'controllers', 'entities/lib/prefix'
{ _id:reconcilerUserId } = __.require('couch', 'hard_coded_documents').users.reconciler

module.exports = (entity)->
  Promise.all [
    searchEntityDuplicatesSuggestions entity
    getAuthorWorksData entity._id
  ]
  .spread (suggestionEntities, authorWorksData)->
    { labels, langs, authorId } = authorWorksData
    Promise.all(suggestionEntities.map(checkSuggestionsOccurences(authorWorksData)))
    .then (res)->
      console.log ".--##########--.", res
      numberOfOccurences = _.compact(res).length
      if numberOfOccurences == 0
        relationScore = calculateRelationScore suggestionEntities
        Promise.all suggestionEntities.map(create(authorWorksData, relationScore))
      else if numberOfOccurences == 1
        suggestionEntity = _.find res, 'hasWorksLabelsOccurrence'
        turnIntoRedirection reconcilerUserId, authorId, suggestionEntity.uri
      else

checkSuggestionsOccurences = (authorWorksData)->
  return (suggestionEntity)->
    { labels, langs, authorId } = authorWorksData
    hasWorksLabelsOccurrence authorId, labels, langs
    .then (worksLabelsOccurrence)->
      if worksLabelsOccurrence then true else false

create = (authorWorksData, relationScore)->
  return (suggestionEntity)->
    { authorId } = authorWorksData
    suggestionUri = suggestionEntity.uri
    _.type suggestionUri, 'string'
    return {
      type: 'deduplicate'
      suspectUri: prefixifyInv(authorId)
      suggestionUri: suggestionEntity.uri
      lexicalScore: suggestionEntity._score
      relationScore: relationScore
    }

getAuthorWorksData = (authorId)->
  entities_.byClaim 'wdt:P50', "inv:#{authorId}", true, true
  .then (works)->
    # works = [
    #   { labels: { fr: 'Matiere et Memoire'} },
    #   { labels: { en: 'foo' } }
    # ]
    base = { authorId, labels: [], langs: [] }
    worksData = works.reduce aggregateWorksData, base
    worksData.langs = _.uniq worksData.langs
    return worksData

aggregateWorksData = (worksData, work)->
  for lang, label of work.labels
    worksData.labels.push label
    worksData.langs.push lang
  return worksData
