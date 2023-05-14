//
//  Functions.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

enum CloudFunction {

    case callRequest(callData: StartCallData)
    case callAnswered(answerCallData: AnswerCallData)
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
        case .callAnswered:
            return "callAnsweredRequest"
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
                "channel"   : callData.channel,
                "bundleId"  : callData.bundleId,
                "callerName": callData.callername,
                "callerId"  : callData.calleeid,
                "calleeName": callData.callername,
                "calleeId"  : callData.calleeid
            ]
        case .callAnswered(let callData):
            return [
                "bundleId"  : callData.bundleId,
                "channel"   : callData.channel,
                "callerId"  : callData.callerid,
                "callState" : callData.callState.rawValue
            ]
        }
    }


}
