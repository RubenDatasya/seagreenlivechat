
const admin = require('firebase-admin');
const apn = require('apn');
const { getCertificatesOptions } = require('./Utils')

const LOG_TAG =  "PushHandlers"


function sendVoipPushToApns(deviceToken,payload) {
    console.log(LOG_TAG + " sendVoipPushToApns");
      var apnProvider = new apn.Provider(getCertificatesOptions());
      var note = new apn.Notification();

      note.body = "Call entering";
      note.topic = `${payload.bundleId}.voip`;
      note.payload = payload

      apnProvider.send(note, deviceToken).then( (result) => {
         console.log(LOG_TAG + " Push send result: " + result)
      }).catch(error => {
          console.log(LOG_TAG + " Push send result: " + error)
      });
  }

  /**
 * Sends push to Firebase for Call notification
 * @param {String} calleetoken 
 * @param {String} callerid 
 * @param {String} channel 
 */
function sendPushToFirebase(calleetoken,callerid,channel, callerName){
    console.log(LOG_TAG + "sendPushToFirebase, deviceToken:" + calleetoken + ", callerid:" + callerid + ", channel:" + channel);
  
    const options = {
      priority: "high",
      timeToLive: 60,  //sec
      content_available: true
      };
  
    admin.messaging().sendToDevice(calleetoken,getPayload(callerid,channel, callerName),options).then((result) => {
      if(result.results[0].messageId){
        console.log(LOG_TAG + " Push send success , messageId: " + result.results[0].messageId)
      }else {
        console.error(LOG_TAG + " Push send fail , error: " + result.results[0].error.message)
      }
    });
  }

  module.exports =  {
    sendVoipPushToApns,
    sendPushToFirebase
  }