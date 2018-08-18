CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ getByUris } = require '../utils/entities'
{ authReq, undesiredErr } = __.require 'apiTests', 'utils/utils'
{ collectEntities } = require '../fixtures/tasks'
{ getByScore } = require '../utils/tasks'

describe 'tasks:has-encyclopedia-occurence', ->
  it 'should auto-merge entities if worksLabelsOccurrence match', (done)->
    authReq 'post', '/api/entities?action=create',
      labels: { en: 'Victor Hugo' }
      claims:
        'wdt:P31': [ 'wd:Q5' ]
    .then (res)->
      authorUri = "inv:#{res._id}"
      authReq 'post', '/api/entities?action=create',
        labels: { en: 'Ruy Blas' }
        claims:
          'wdt:P31': [ 'wd:Q571' ]
          'wdt:P50': [ authorUri ]
      .then -> collectEntities { refresh: true }
      .then (res)-> getByUris authorUri
      .then (authorEntity)->
        authorEntity.type.should.not.equal 'human'
        done()
      .catch undesiredErr(done)

    return
