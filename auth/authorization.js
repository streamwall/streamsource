const AccessControl = require('accesscontrol')
const ac = new AccessControl()

ac.grant('admin')
  .createAny('stream')
  .readAny('stream')
  .updateAny('stream')
  .deleteAny('stream')

ac.grant('editor')
  .createAny('stream')
  .readAny('stream')
  .updateAny('stream')
  .deleteAny('stream')

ac.grant('default')
  .readAny('stream')

ac.lock()
exports.accessControl = ac
