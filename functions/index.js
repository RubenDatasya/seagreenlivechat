
const functions = require('firebase-functions')
const admin = require('firebase-admin')
const { initializeApp } = require('firebase-admin/app')
const {
    RtcTokenBuilder,
    RtcRole,
    RtmRole,
    RtmTokenBuilder
} = require('agora-access-token')

var apn = require('apn')
const { error } = require('firebase-functions/logger')

const appID = "0089641598304276ab3e6baf141c0258";
const appCertificate = "12e9058b7aa64cd6898f2ab446f3e31f";

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started
//

const defaultApp = initializeApp()
const db = admin.firestore()

const getTimeStamp = (interval) => {
    const expirationTimeInSeconds = interval
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const privilegeExpired = currentTimestamp + expirationTimeInSeconds
    return privilegeExpired
}

exports.getRtcToken = functions.https.onCall((data, context) => {
    try {
        const role = RtcRole.PUBLISHER
        const privilegeExpired = getTimeStamp(1446455471)
        const channelName = data.channelName
        const uid =  data.uid

        const token = RtcTokenBuilder.buildTokenWithUid(
            appID,
            appCertificate,
            channelName,
            uid,
            role,
            privilegeExpired
            )

        return {
            data: {
                value: token            
            }
        }

     } catch(error) {
        console.log(error)
     }
})

exports.getRtmToken = functions.https.onCall((data, context) => {

    const userAccount = data.userid

    try {
        const token =  RtmTokenBuilder.buildToken(
            appID,
            appCertificate,
            userAccount,
            RtmRole.Rtm_User,
            getTimeStamp(1446455471)
        )
    
        return {
            data: {
                value: token            
            }
        }
    } catch(error) {
        console.log(error)
    }
})

exports.callRequest = functions.https.onCall( async (data) => {

    const callee = data.calleeName;
    console.log(LOG_TAG + " callee: " + callee)
    const callerName = data.callerName
    const roomName = data.channelName
    console.log(LOG_TAG + " payload: " + callerName)
    const tokensPath = admin.firestore().collection('pushtokens').where("ownedby", "==", callee).get();
    const promise = tokensPath.then(snapshot => {
        console.log(LOG_TAG + " doc: ", snapshot.docs.length)

        snapshot.docs.forEach( doc => {
            console.log(LOG_TAG + " doc: ", doc.data())
            const data = doc.data()
            console.log(LOG_TAG + " data: ", data)
            const calleeToken = data["pushToken"]
            //To setup for android handling
            //const targetDeviceOS = data[callee]['deviceOS']
            console.log(LOG_TAG + " calleeToken: ", calleeToken)
            //if(targetDeviceOS == "iOS"){
              sendPushToFirebase(calleeToken,callerName,roomName)
              sendVoipPushToApns(calleeToken,callerName,roomName)
            // }else if (targetDeviceOS == "Android"){
            //   sendPushToFirebase(calleeToken,callerName,roomName)
            // }else {
            //   // Invalid targetDeviceOS
            //   console.error("Invalid targetDeviceOS received, targetDeviceOS : ", targetDeviceOS)
            // }
        })


    });
    promise.catch(error => {
       // Need to have better error management
        console.error(error);
    });

    await Promise.all([promise])

})


/**
 * Sends push to APNS for VOIP Call
 * @param {String} deviceToken 
 * @param {String} callerName 
 * @param {String} roomName 
 */

const LOG_TAG = "Voip Flow"

const getPayload = (callerName, channelName) => {
    const payload = {
        notification: {
          title: "Phone Call",
          body: "Answer",
          link: `app://seagreen/chat/${callerName}`
        },
        data: {
          conversationType : "videocall",
          channelName: channelName,
          caller : callerName
        }
      };

      return payload
}

function sendVoipPushToApns(deviceToken,callerName,roomName) {
  console.log(LOG_TAG + " sendVoipPushToApns, deviceToken:" + deviceToken + ", callerName:" + callerName + ", roomName:" + roomName);
    var options = {
        token: {
          key: "./certs/AuthKey_K2B7NYR9XB.p8",
          keyId: "K2B7NYR9XB",
          teamId: "LVKN97J3GA"
        },
        production: true
      };
      
      var apnProvider = new apn.Provider(options);
      var note = new apn.Notification();

    note.expiry = Math.floor(Date.now() / 1000) + 3600; 
    note.badge = 3;
    note.sound = "ping.aiff";
    note.alert = "You have a new call";
    note.payload = {'callerName': callerName,"roomName":roomName};
    note.topic = "com.datasya.seagreenlivevideo";

    apnProvider.send(note, deviceToken).then( (result) => {
       console.log(LOG_TAG + " Push send result: " + result)
    }).catch(error => {
        console.log(LOG_TAG + " Push send result: " + error)
    });
}

/**
 * Sends push to Firebase for Call notification
 * @param {String} deviceToken 
 * @param {String} callerName 
 * @param {String} roomName 
 */
function sendPushToFirebase(deviceToken,callerName,roomName){
  console.log(LOG_TAG + "sendPushToFirebase, deviceToken:" + deviceToken + ", callerName:" + callerName + ", roomName:" + roomName);

  const options = {
    priority: "high",
    timeToLive: 60,  //60 sec
    content_available: true
};

  admin.messaging().sendToDevice(deviceToken,getPayload(callerName,roomName),options).then((result) => {
    if(result.results[0].messageId){
      console.log(LOG_TAG + " Push send success , messageId: " + result.results[0].messageId)
    }else {
      console.error(LOG_TAG + " Push send fail , error: " + result.results[0].error.message)
    }
    
  });
}


// For regular push case function below can be use.
function sendPushToApns(deviceToken) {
    var options = {
        token: {
          key: "./certs/APNsAuthKey_XXXXXXXXXX.p8",
          keyId: "key-id",
          teamId: "developer-team-id"
        },
        production: false
      };
      
    var apnProvider =  apn.Provider(options);
    var note =  apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    note.badge = 3;
    note.sound = "ping.aiff";
    note.alert = "\uD83D\uDCE7 \u2709 You have a new message";
    note.payload = {'messageFrom': 'John Appleseed'};
    note.topic = "<Your app bundle id>";

    apnProvider.send(note, deviceToken).then( (result) => {
      console.log(LOG_TAG + " Push send result: " + result)
    });
}
