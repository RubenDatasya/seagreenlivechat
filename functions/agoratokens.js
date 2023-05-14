
const { functions }  = require('./adminfile')

const {
    RtcTokenBuilder,
    RtcRole,
    RtmRole,
    RtmTokenBuilder
} = require('agora-access-token');


const appID = "0089641598304276ab3e6baf141c0258";
const appCertificate = "12e9058b7aa64cd6898f2ab446f3e31f";

const getTimeStamp = (interval) => {
    const expirationTimeInSeconds = interval
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const privilegeExpired = currentTimestamp + expirationTimeInSeconds
    return privilegeExpired
}

const getRtcToken = functions.https.onCall((data, context) => {
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

const getRtmToken = functions.https.onCall((data, context) => {

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

module.exports = {
    getRtcToken,
    getRtmToken
}
