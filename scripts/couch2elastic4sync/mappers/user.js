const __ = require('config').universalPath
const { pick, without } = require('lodash')
const publicAttributes = __.require('models', 'attributes/user').public
// Omit snapshot as it contains private and semi priavte data
const publicAttributesStrict = without(publicAttributes, 'snapshot')

module.exports = function (doc) {
  if (doc.type === 'user') {
    return pick(doc, publicAttributesStrict)
  }
}
