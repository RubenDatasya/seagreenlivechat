//
//  AgoraRtm.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 04/05/2023.
//

import Foundation
import AgoraRtmKit

class AgoraRtm {

    static let shared = AgoraRtm()

    private var agoraRtm: AgoraRtmKit! {
        didSet {
            self.kit = agoraRtm
        }
    }

    private(set) var kit: AgoraRtmKit!
    private lazy var chatApi = LiveChatTokenAPI()
    private var rtmChannel: AgoraRtmChannel?


    private init() {}

    func initalize() {
        agoraRtm = .init(appId: Constants.Secret.appid, delegate: nil)
    }

    func setDelegate(_ delegate: AgoraRtmDelegate){
        agoraRtm.agoraRtmDelegate = delegate
    }

    @discardableResult
    func joinMessageChannel(delegate: AgoraRtmChannelDelegate) async throws -> Bool  {
        let token = await chatApi.fetch(userid:  Constants.Credentials.currentUser)
        let login = await agoraRtm.login(byToken: token.value, user: Constants.Credentials.currentUser)

        if login == .ok {
            try createMessageChannel(delegate: delegate)
            let result = await rtmChannel?.join()
            Logger.info("joinMessageChannel, success")
            return true
        } else {
            Logger.info("joinMessageChannel  AgoraRtmLoginErrorCode failure \(login)")
            return false
        }
    }

    func sendMessage(event: ChannelMessageEvent) {
        self.rtmChannel?.send(AgoraRtmMessage(text: event.title )){ error in
            Logger.error("sendMessage \(error)")

        }
    }

    func leaveChannel() {
         rtmChannel?.leave { (error) in
             Logger.error("leaveChannel \(error)")
         }
        rtmChannel = nil
     }

    private func createMessageChannel(delegate: AgoraRtmChannelDelegate) throws {
        guard let rtmChannel = agoraRtm.createChannel(withId: Constants.Credentials.channel, delegate: delegate) else {
            throw LiveChatAlert.channelError
        }
        self.rtmChannel = rtmChannel
    }
}
