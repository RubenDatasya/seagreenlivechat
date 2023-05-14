const { getRtcToken, getRtmToken  } = require('./agoratokens');
const { callAnsweredRequest, callRequest} = require('./CallHandlers')

module.exports = {
    getRtcToken, 
    getRtmToken, 
    callAnsweredRequest,
    callRequest
}
