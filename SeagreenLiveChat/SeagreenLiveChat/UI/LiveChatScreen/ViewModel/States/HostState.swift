//
//  enum HostState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation

enum HostState: Hashable {
    case received(uid : UInt)
    case disconnected

    var isConnected: Bool {
        switch self {
        case .received:
            return true
        case .disconnected:
            return false
        }
    }
}
