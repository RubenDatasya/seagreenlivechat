//
//  Functions.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

enum CloudFunction {
    case getRtcToken(channelName: String, uid: UInt)
    case getRtmToken(userid: String)

    var function: String {
        switch self {
        case .getRtcToken:
            return "getRtcToken"
        case .getRtmToken:
            return "getRtmToken"
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
                "userid": userid
            ]
        }
    }


}