//
//  ChatChannel.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

struct ChatChannel: FirebaseCodable, Identifiable {
    var id: String = UUID().uuidString
    var opened: Date = .now
    var name: String
    var openedBy: String
    var peer: String?
}
