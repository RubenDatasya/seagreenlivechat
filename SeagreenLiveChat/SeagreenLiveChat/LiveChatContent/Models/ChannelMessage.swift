//
//  ChannelMessage.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import StreamChat

enum ChannelMessageEvent : String, Codable  {

    case zoomIn 
    case zoomOut
    case brightnessUp
    case brightnessDown
    case flashOn
    case flashOff
    case leave
}


struct ChannelMessage: CustomEventPayload {

    static var eventType: StreamChat.EventType = .healthCheck

    var event : ChannelMessageEvent


}

