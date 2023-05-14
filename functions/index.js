const { getRtcToken, getRtmToken  } = require('./agoratokens');
const { callAcceptedRequest, callRequest, endCallRequest} = require('./CallHandlers')
require('events').EventEmitter.prototype._maxListeners = 100;

module.exports = {
    getRtcToken, 
    getRtmToken, 
    callAcceptedRequest,
    callRequest,
    endCallRequest
}
