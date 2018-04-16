CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'

byScore = '/api/tasks?action=by-score&limit=1000'
updateRelationScore = '/api/tasks?action=update-relation-score&id='

{ Promise } = __.require 'lib', 'promises'
{ authReq, nonAuthReq, undesiredErr } = __.require 'apiTests', 'utils/utils'
{ createTask, createTaskWithSuggestionAuthor } = require '../fixtures/tasks'

describe 'tasks:update-relation-score', ->
  describe 'when a task have no homonym', ->
    it 'should have a relationScore equal to 1', (done)->
      createTaskWithSuggestionAuthor
        authorName: 'Stanilas Lem'
        suggestionUri: 'wd:Q6530'
      .then (task)->
        authReq 'put', updateRelationScore + task._id
        .then ->
          task.relationScore.should.equal 1
          done()
      .catch undesiredErr(done)

      return

  describe 'when tasks have same suspect with different wd suggestions', ->
    it 'should relationScore should be depreciated', (done)->
      createTaskWithSuggestionAuthor
        authorName: 'Jim Vance'
        suggestionUri: 'wd:Q27042411'
      .then (task)->
        createTask task.suspectUri
        .then (res)->
          authReq 'put', updateRelationScore + task._id
          .then -> authReq 'get', "/api/tasks?action=by-ids&ids=#{task._id}"
          .then (res)->
            updatedTask = res.tasks[0]
            updatedTask.relationScore.should.be.below 1
            done()
      .catch undesiredErr(done)

      return

    it 'should relationScore should be rounded at 2 decimals', (done)->
      createTask null, 'wd:Q27042411'
      .then (task)->
        createTask task.suspectUri, 'wd:Q42'
      .then (task)->
        createTask task.suspectUri, 'wd:Q565'
        .then (res)->
          authReq 'put', updateRelationScore + task._id
          .then -> authReq 'get', "/api/tasks?action=by-ids&ids=#{task._id}"
          .then (res)->
            updatedTask = res.tasks[0]
            updatedTask.relationScore.toString().length.should.belowOrEqual 4
            done()
      .catch undesiredErr(done)

      return
