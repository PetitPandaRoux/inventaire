CONFIG = require 'config'
__ = CONFIG.root
_ = __.require 'builders', 'utils'
Radio = __.require 'lib', 'radio'
User = __.require 'models', 'user'


module.exports = (db)->

  token_ = {}

  token_.sendValidationEmail = (user)->
    unless user.validatedEmail
      Radio.emit 'validation:email', user
    return user

  token_.byEmailValidationToken = (token)->
    db.viewFindOneByKey 'byEmailValidationToken', token

  token_.confirmEmailValidity = (token)->
    token_.byEmailValidationToken(token)
    .then updateIfValidToken.bind(null, token)

  updateIfValidToken = (token, user)->
    _.log user, 'user byEmailValidationToken'
    if user? and User.validToken(token, user.emailValidation)
      db.update user._id, emailIsValid
    else
      err = new Error 'token is invalid or expired'
      err.type = 'invalid_token'
      throw err

  return token_


emailIsValid = (user)->
  user.validatedEmail = true
  return _.omit user, 'emailValidation'
