//
//  ChannelMessage.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

enum ChannelMessageEvent : String, Codable  {
    case zoomIn
    case zoomOut
    case brightnessUp
    case brightnessDown
    case flashOn
    case flashOff
    case leave
    case unknown

    static func value( _ from : String) -> Self{
        switch from {
        case ChannelMessageEvent.zoomIn.rawValue:
            return .zoomIn
        case  ChannelMessageEvent.zoomOut.rawValue:
            return .zoomOut
        case  ChannelMessageEvent.brightnessUp.rawValue:
            return .brightnessUp
        case  ChannelMessageEvent.brightnessDown.rawValue:
            return .brightnessDown
        case  ChannelMessageEvent.flashOn.rawValue:
            return .flashOn
        case  ChannelMessageEvent.flashOff.rawValue:
            return .flashOff
        case  ChannelMessageEvent.leave.rawValue:
            return .leave
        default:
            return .unknown
        }
    }
}
