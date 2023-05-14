
const { functions, admin }  = require('./adminfile')
const { sendPushToFirebase, sendVoipPushToApns } = require('./PuchHandlers')

const ownedby = 'ownedby';
const pushCollection = 'pushtokens';
const LOG_TAG =  "CallHandlers"

const callState = {
    pending     : 'PENDING',
    answered    : 'ANSWERED',
    declined    : 'DECLINED',
    notAnswered : 'NOT_ANSWERED',
    ended       : 'ENDED'
};

const getCallState = (from) => {
    switch (from) {
        case callState.answered:
            return callState.answered
        case callState.pending:
            return callState.pending
        case callState.declined:
            return callState.declined
        case callState.notAnswered:
            return callState.notAnswered
        case callState.ended:
            return callState.ended
        default:
            return callState.pending
    }
}

const findPushReceiver = (id) => {
    const tokensPath = admin.firestore().collection(pushCollection).where(ownedby, "==", id).get()
    return tokensPath
}

const handlePush = (targetDeviceOS,calleeToken,callerid,channel, callername, bundleId, callState) => {
    if(targetDeviceOS == "iOS"){
        sendVoipPushToApns(calleeToken,callerid,channel, callername, bundleId, callState)
       }else if (targetDeviceOS == "Android"){
         sendPushToFirebase(calleeToken,callerid,channel)
       }
}


const callRequest = functions.https.onCall( async (data) => {

    console.log(LOG_TAG + " callRequest data " + data)

    const calleeid   = data.calleeId;
    const callerid   = data.callerId
    const callername = data.callerName
    const calleename = data.calleeName
    const channel    = data.channel
    const bundleId   = data.bundleId
    const tokensPath = findPushReceiver(calleeid)

    const promise = tokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)

        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const calleeToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(callee): ", calleeToken)

            handlePush(targetDeviceOS,
                        calleeToken,
                        callerid,
                        channel,
                        calleename,
                        bundleId,
                        callState.pending)
        })
    });
    promise.catch(error => {
       // Need to have better error management
        console.error(error);
    });
    await Promise.all([promise])
})

const callAnsweredRequest =  functions.https.onCall(async(data) => {

    const callerId  = data.callerId
    const channel   = data.channel
    const bundleId  = data.bundleId
    const callState = getCallState(data.callState)
    const tokensPath = findPushReceiver(callerId)

    const promise = tokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)
        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const deviceToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(caller): ", deviceToken)

            handlePush(targetDeviceOS,
                        deviceToken,
                        callerId,
                        channel,
                        '',
                        bundleId,
                        callState)
        })
    });

    promise.catch(error => {
       // Need to have better error management
        console.error(error);
    });
    await Promise.all([promise])

})

module.exports = {
    callRequest,
    callAnsweredRequest
}