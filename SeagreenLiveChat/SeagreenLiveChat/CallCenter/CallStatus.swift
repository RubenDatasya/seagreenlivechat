//
//  CallState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 14/05/2023.
//

import Foundation

enum CallStatus: String  {
    case incoming       = "INCOMING"
    case accepted       = "ACCEPTED"
    case declined       = "DECLINED"
    case notAnswered    = "NOT_ANSWERED"
    case ended          = "ENDED"

    static func getState(from value: String) -> CallStatus {
        switch value {
        case CallStatus.incoming.rawValue:
            return .incoming
        case CallStatus.accepted.rawValue:
            return .accepted
        case CallStatus.declined.rawValue:
            return .declined
        case CallStatus.notAnswered.rawValue:
            return .notAnswered
        case CallStatus.ended.rawValue:
            return .ended
        default:
            fatalError("Unknow callstate sent \(value)")
        }
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func toCallStatus() -> CallStatus {
        return CallStatus.getState(from: self["callState"] as! String)
    }
}
