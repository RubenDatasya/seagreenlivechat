//
//  CallData.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

struct CallData {
    var channel          : String
    var callId           : UUID
    var callerid         : String
    var calleeid         : String
    var callerName       : String
    var bundleId         : String
}

extension CallData {

    static func toCallData(_ userinfo: [AnyHashable: Any]) -> Self {
        let callerId    = userinfo["callerId"] as! String
        let calleeId    = userinfo["calleeId"] as! String
        let callerName  = userinfo["callerName"] as! String
        let channel     = userinfo["channel"]   as! String
        let bundleId    = userinfo["bundleId"] as! String
        let callId      =  UUID(uuidString: userinfo["callId"] as! String)
        return CallData(channel: channel, callId: callId!, callerid: callerId, calleeid: calleeId, callerName: callerName, bundleId: bundleId)
    }

}

