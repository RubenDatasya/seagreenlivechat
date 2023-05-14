//
//  NotificationCenter + Extension.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

extension NotificationCenter {
    static func answeredCall(call: CallNotification) {
        NotificationCenter.default.post(name: CallNotification.name, object: call)
    }
}
