//
//  CallNotificationAnswered.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

class CallNotification {

    enum CallState {
        case answered(callData: CallData)
        case started
        case ended
    }

    static let name: Notification.Name = Notification.Name("com.seagreen.call")

    var state: CallState

    init(state: CallState) {
        self.state = state
    }
}
