//
//  ChannelMessage.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

enum ChannelMessageEvent: Codable, Hashable  {
    case participantShares
    case participantStoppedSharring
    case zoomIn
    case zoomOut
    case brightnessUp
    case brightnessDown
    case flash
    case flashDown
    case leave
    case focus(jsonPoint: String)
    case unknown

    var title: String {
        switch self {
        case .participantShares:
            return "participantShares"
        case .participantStoppedSharring:
            return "participantStoppedSharring"
        case .zoomIn:
            return "zoomIn"
        case .zoomOut:
            return "zoomOut"
        case .brightnessUp:
            return "brightnessUp"
        case .brightnessDown:
            return "brightnessDown"
        case .flash:
            return "flash"
        case .flashDown:
            return "flashDown"
        case .leave:
            return "leave"
        case .focus(let json):
            return json
        case .unknown:
            return "unknown"
        }
    }

    static func value( _ from : String) -> Self{
        switch from {
        case  ChannelMessageEvent.participantStoppedSharring.title:
            return .participantStoppedSharring
        case  ChannelMessageEvent.participantShares.title:
            return .participantShares
        case ChannelMessageEvent.zoomIn.title:
            return .zoomIn
        case  ChannelMessageEvent.zoomOut.title:
            return .zoomOut
        case  ChannelMessageEvent.brightnessUp.title:
            return .brightnessUp
        case  ChannelMessageEvent.brightnessDown.title:
            return .brightnessDown
        case  ChannelMessageEvent.flash.title:
            return .flash
        case  ChannelMessageEvent.flashDown.title:
            return .flashDown
        case  ChannelMessageEvent.leave.title:
            return .leave
        default:
            return .unknown
        }
    }
}
