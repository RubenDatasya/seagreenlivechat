//
//  CallState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 14/05/2023.
//

import Foundation

enum CallState: String  {
    case pending        = "PENDING"
    case answered       = "ANSWERED"
    case declined       = "DECLINED"
    case notAnswered    = "NOT_ANSWERED"
    case ended          = "ENDED"

    static func getState(from value: String) -> CallState {
        switch value {
        case CallState.pending.rawValue:
            return .pending
        case CallState.answered.rawValue:
            return .answered
        case CallState.declined.rawValue:
            return .declined
        case CallState.notAnswered.rawValue:
            return .notAnswered
        case CallState.ended.rawValue:
            return .ended
        default:
            fatalError("Unknow callstate sent \(value)")
        }
    }
}
