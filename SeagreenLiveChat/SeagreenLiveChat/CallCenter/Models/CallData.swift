//
//  CallData.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

struct CallData {
    var channel          : String
    var callerid         : String
    var callerName       : String
    var bundleId         : String
    var callState        : CallState
}

extension CallData {

    static func toCallData(_ userinfo: [AnyHashable: Any]) -> Self {
        let callerId    = userinfo["callerId"] as! String
        let callerName  = userinfo["callerName"] as! String
        let channel     = userinfo["channel"] as! String
        let bundleId    = userinfo["bundleId"] as! String
        let callState   = CallState.getState(from: userinfo["callState"] as! String)
        return CallData(channel: channel, callerid: callerId, callerName: callerName, bundleId: bundleId , callState: callState)
    }

}
