CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
responses_ = __.require 'lib', 'responses'
error_ = __.require 'lib', 'error/error'
{ getImageByUrl } = __.require 'data', 'dataseed/dataseed'
{ enabled:dataseedEnabled } = CONFIG.dataseed

module.exports = (req, res, next)->
  { url } = req.body

  # If dataseed is disabled, we simply return the same url,
  # instead of converting it to an IPFS hash
  unless dataseedEnabled then res.json { url }

  getImageByUrl url
  .then responses_.Send(res)
  .catch error_.Handler(req, res)
