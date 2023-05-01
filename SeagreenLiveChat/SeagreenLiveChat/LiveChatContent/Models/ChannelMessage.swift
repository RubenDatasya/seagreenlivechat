//
//  ChannelMessage.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

enum ChannelMessageEvent : String, Codable {
    case zoomIn 
    case zoomOut
    case brightnessUp
    case brightnessDown
    case flashOn
    case flashOff
    case leave
}


struct ChannelMessage: Codable {

    var event : ChannelMessageEvent

    func serialize() -> String {
        let data =  try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

