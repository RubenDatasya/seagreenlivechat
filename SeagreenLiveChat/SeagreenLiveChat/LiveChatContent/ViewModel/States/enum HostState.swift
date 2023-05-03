//
//  enum HostState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation

enum HostState {
    case none(uid: UInt)
    case received(uid : UInt)
    case disconnected(uid : UInt)
}
