
const functions = require('firebase-functions')
const admin = require('firebase-admin')
const { initializeApp } = require('firebase-admin/app');
const {
    RtcTokenBuilder,
    RtcRole,
    RtmRole,
    RtmTokenBuilder
} = require('agora-access-token');


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
        const privilegeExpired = getTimeStamp(3600)
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
