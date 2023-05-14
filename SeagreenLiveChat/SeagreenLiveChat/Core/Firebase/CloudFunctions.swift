//
//  Functions.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

enum CloudFunction {

    case callRequest(callData: StartCallData)
    case callAccepted(answerCallData: AcceptedCallData)
    case endCallRequest(endCallData: EndCallData)
    case getRtcToken(channelName: String, uid: UInt)
    case getRtmToken(userid: String)

    var function: String {
        switch self {
        case .getRtcToken:
            return "getRtcToken"
        case .getRtmToken:
            return "getRtmToken"
        case .callRequest:
            return "callRequest"
        case .callAccepted:
            return "callAcceptedRequest"
        case .endCallRequest:
            return "endCallRequest"
        }
    }

    var params: [String:Any] {
        switch self {
        case .getRtcToken(let channelName, let uid):
            return [
                "channelName": channelName,
                "uid"        : uid
            ]
        case .getRtmToken(let userid):
            return [
                "userid"    : userid
            ]
        case .callRequest(let callData):
            return [
                "callId"    : callData.id.uuidString,
                "channel"   : callData.channel,
                "bundleId"  : callData.bundleId,
                "callerName": callData.callername,
                "callerId"  : callData.callerid,
                "calleeName": callData.callername,
                "calleeId"  : callData.calleeid
            ]
        case .callAccepted(let callData):
            return [
                "bundleId"  : callData.bundleId,
                "callId"    : callData.callId.uuidString,
                "channel"   : callData.channel,
                "callerId"  : callData.callerid,
                "calleeId"  : callData.calleeid,
            ]
        case .endCallRequest(let callData):
            return [
                "callerId"  : callData.callerId,
                "calleeId"  : callData.calleeId,
                "bundleId"  : callData.bundleId
            ]
        }

    }
}
