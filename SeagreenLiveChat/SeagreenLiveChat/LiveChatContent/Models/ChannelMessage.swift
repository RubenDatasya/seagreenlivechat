//
//  ChannelMessage.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

enum ChannelMessageEvent : String, Codable  {
    case participantShares
    case participantStoppedSharring
    case zoomIn
    case zoomOut
    case brightnessUp
    case brightnessDown
    case flash
    case leave
    case unknown

    static func value( _ from : String) -> Self{
        switch from {
        case  ChannelMessageEvent.participantStoppedSharring.rawValue:
            return .participantStoppedSharring
        case  ChannelMessageEvent.participantShares.rawValue:
            return .participantShares
        case ChannelMessageEvent.zoomIn.rawValue:
            return .zoomIn
        case  ChannelMessageEvent.zoomOut.rawValue:
            return .zoomOut
        case  ChannelMessageEvent.brightnessUp.rawValue:
            return .brightnessUp
        case  ChannelMessageEvent.brightnessDown.rawValue:
            return .brightnessDown
        case  ChannelMessageEvent.flash.rawValue:
            return .flash
        case  ChannelMessageEvent.leave.rawValue:
            return .leave
        default:
            return .unknown
        }
    }
}
