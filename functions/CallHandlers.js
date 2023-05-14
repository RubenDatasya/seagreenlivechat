
const { functions, admin }  = require('./adminfile')
const { sendPushToFirebase, sendVoipPushToApns } = require('./PuchHandlers')

const ownedby = 'ownedby';
const pushCollection = 'pushtokens';
const LOG_TAG =  "CallHandlers"

const callState = {
    incoming    : 'INCOMING',
    accepted    : 'ACCEPTED',
    declined    : 'DECLINED',
    notAnswered : 'NOT_ANSWERED',
    ended       : 'ENDED'
};

const getCallState = (from) => {
    switch (from) {
        case callState.accepted:
            return callState.accepted
        case callState.incoming:
            return callState.incoming
        case callState.declined:
            return callState.declined
        case callState.notAnswered:
            return callState.notAnswered
        case callState.ended:
            return callState.ended
        default:
            return callState.incoming
    }
}

const findPushReceiver = (id) => {
    const tokensPath = admin.firestore().collection(pushCollection).where(ownedby, "==", id).get()
    return tokensPath
}

const handlePush = (
    targetDeviceOS,
    deviceToken, 
    callerid, 
    calleeId, 
    channel, 
    callername, 
    callId,
    bundleId ) => {
    if(targetDeviceOS == "iOS"){

        var payload = {
            "aps": { "content-available": 1 },
            "callerName": callername,
            "callerId"  : callerid,
            "calleeId"  : calleeId,
            "channel"   : channel,
            "bundleId"  : bundleId,
            "callId"    : callId,
            "callState" : callState.incoming
        };

        sendVoipPushToApns(deviceToken,payload)
       } else if (targetDeviceOS == "Android"){
         sendPushToFirebase(deviceToken,callerid,channel)
       }
}

const handleAnswerPush = (
        targetDeviceOS,
        deviceToken,
        channel ,
        otherUser,
        callId,
        bundleId
      ) => {
    if(targetDeviceOS == "iOS"){

        var payload = {
            "aps": { "content-available": 1 },
            "otherUser" : otherUser,
            "channel"   : channel,
            "bundleId"  : bundleId,
            "callId"    : callId,
            "callState" : callState.accepted
        };

        sendVoipPushToApns(deviceToken,payload)

       } else if (targetDeviceOS == "Android"){

         sendPushToFirebase(calleeToken,callerid,channel)
       }
}

const handleEndPush = (
    targetDeviceOS,
    deviceToken,
    callerId,
    calleeId,
    bundleId
  ) => {
if(targetDeviceOS == "iOS"){

    var payload = {
        "aps": { "content-available": 1 },
        "callerId" : callerId,
        "calleeId"   : calleeId,
        "bundleId"  : bundleId,
        "callState" : callState.ended
    };

    sendVoipPushToApns(deviceToken,payload)

   } else if (targetDeviceOS == "Android"){

     sendPushToFirebase(calleeToken,callerid,channel)
   }
}


const callRequest = functions.https.onCall( async (data) => {

    console.log(LOG_TAG + " callRequest data " + data)

    const callId     = data.callId
    const calleeid   = data.calleeId
    const callerid   = data.callerId
    const callername = data.callerName
    const calleename = data.calleeName
    const channel    = data.channel
    const bundleId   = data.bundleId
    const tokensPath = findPushReceiver(calleeid)

    console.log(LOG_TAG + "callRequest  callid: ", callId)


    const promise = tokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)

        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const calleeToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(callee): ", calleeToken)

            handlePush( targetDeviceOS,
                        calleeToken,
                        callerid,
                        calleeid,
                        channel,
                        calleename,
                        callId,
                        bundleId)
        })
    });
    promise.catch(error => {
        console.error(error);
    });
    await Promise.all([promise])
})

const callAcceptedRequest =  functions.https.onCall(async(data) => {

    const callerId  = data.callerId
    const callId    = data.callId
    const channel   = data.channel
    const bundleId  = data.bundleId
    const calleeId  = data.calleeId
    const callState = getCallState(data.callState)
    const callerTokensPath = findPushReceiver(callerId)
    const calleeTokensPath = findPushReceiver(calleeId)

    console.log(LOG_TAG + "callAcceptedRequest  callid: ", callId)


    const callerPromise = callerTokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)
        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const deviceToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(caller): ", deviceToken)

            handleAnswerPush(targetDeviceOS,
                            deviceToken,
                            channel,
                            calleeId,
                            callId,
                            bundleId)
        })
    });

    const calleePromise = calleeTokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)
        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const deviceToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(caller): ", deviceToken)

            handleAnswerPush(
                targetDeviceOS,
                deviceToken,
                channel,
                callerId,
                callId,
                bundleId)
        })
    });



    callerPromise.catch(error => {
        console.error(`callerPromise ${error}`);
    });

    calleePromise.catch(error => {
        console.error(`calleePromise ${error}`);
    });

    await Promise.all([callerPromise, callerPromise])

})

const endCallRequest =  functions.https.onCall(async(data) => {

    const callerId  = data.callerId
    const bundleId  = data.bundleId
    const calleeId  = data.calleeId
    const callerTokensPath = findPushReceiver(callerId)
    const calleeTokensPath = findPushReceiver(calleeId)

    const callerPromise = callerTokensPath.then(snapshot => {
        console.log(LOG_TAG + " endCallRequest  doc: ", snapshot.docs.length)
        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const deviceToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(caller): ", deviceToken)

            handleEndPush(targetDeviceOS,
                            deviceToken,
                            callerId,
                            calleeId,
                            bundleId)
        })
    });

    const calleePromise = calleeTokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)
        snapshot.docs.forEach( doc => {
            const data           = doc.data()
            const deviceToken    = data["pushToken"]
            const targetDeviceOS = data["deviceOS"]
            console.log(LOG_TAG + " receiverToken(caller): ", deviceToken)

            handleEndPush(
                targetDeviceOS,
                deviceToken,
                callerId,
                calleeId,
                bundleId)
        })
    });

    callerPromise.catch(error => {
        console.error(`callerPromise ${error}`);
    });

    calleePromise.catch(error => {
        console.error(`calleePromise ${error}`);
    });

    await Promise.all([callerPromise, callerPromise])

})

module.exports = {
    callRequest,
    callAcceptedRequest,
    endCallRequest
}