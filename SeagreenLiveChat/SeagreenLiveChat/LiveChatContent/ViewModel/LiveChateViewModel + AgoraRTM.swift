//
//  LiveChateViewModel + AgoraRTMChannelDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation
import AgoraRtcKit
import AgoraRtmKit



extension LiveChatViewModel : AgoraRtmDelegate {

    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        print("connectionStateChanged", "\(state) \(state.rawValue), \(reason) \(reason.rawValue)")
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        print("tokenPrivilegeWillExpire")
    }

    func rtmKitTokenDidExpire(_ kit: AgoraRtmKit) {
        print("rtmKitTokenDidExpire")
    }

}


extension LiveChatViewModel: AgoraRtmChannelDelegate {

    func channel(_ channel: AgoraRtmChannel, memberCount count: Int32) {
        print("memberCount, \(count)")
    }

    func channel(_ channel: AgoraRtmChannel, attributeUpdate attributes: [AgoraRtmChannelAttribute]) {
        print("attributeUpdate, attributeUpdate")
    }

    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        print("memberJoined, join")
    }

    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        print("\(member.userId) left")
    }

    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        print("messageReceived \(message.text) from \(member.userId)")
        if member.userId != Constants.Credentials.rtmUser {
            receivedMessage.send(ChannelMessageEvent.value(message.text))
        }
        handleState(ChannelMessageEvent.value(message.text))
    }

}
