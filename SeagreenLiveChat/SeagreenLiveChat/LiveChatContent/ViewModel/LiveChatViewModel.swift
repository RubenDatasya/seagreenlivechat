//
//  LiveChatViewModel.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import Combine
import SwiftUI
import AgoraRtmKit
import AgoraRtcKit

enum CameraState {
    case rear
    case front
}

enum RTCLoginState {
    case disconnected
    case connecting
    case connected
    case failureConnecting
}

class LiveChatViewModel: NSObject, ObservableObject {

    var isConnected:   PassthroughSubject<RTCLoginState, Never> = .init()
    var currentCamera: CameraState = .front
    var cameraToggle:  PassthroughSubject<CameraState, Never> = .init()
    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()
    var newHostEvent:  PassthroughSubject<UInt, Never> = .init()
    var messageEvent:  PassthroughSubject<ChannelMessage, Never> = .init()
    var userRole: AgoraClientRole = .broadcaster

    lazy var chatApi = LiveChatTokenAPI()
    lazy var messsagingApi = SignalingTokenAPI()

    var agoraEngine: AgoraRtcEngineKit!
    var agoraRtm: AgoraRtmKit!
    var rtmChannel: AgoraRtmChannel?

    var subscriptions: Set<AnyCancellable> = .init()



    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.shared.appId
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraRtm = .init(appId: Constants.shared.appId, delegate: self)
        observeRtcLoginState()
    }

    func joinChannel() async  {
        let token = await chatApi.fetch(userid: Constants.shared.currentUser)

        if await !AVPermissionManager.shared.checkForPermissions() {
            alertSubject.send(.permissionError)
            return
        }

        let option = AgoraRtcChannelMediaOptions()
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
        } else {
            option.clientRoleType = .audience
        }
        option.channelProfile = .communication

        self.isConnected.send(.connecting)

         let result = agoraEngine.joinChannel(
            byToken: Constants.shared.token, channelId: Constants.shared.channel, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in }
        )
         if result == 0 {
             self.isConnected.send(.connected)
        }
    }

    func leaveChannels() {
        leaveChannel()
        leaveMessageChannel()
    }

    func sendMessage(event: ChannelMessageEvent) {
        self.rtmChannel?.send(AgoraRtmMessage(text: event.rawValue )){ error in
            print("sendMessage \(error)", error.rawValue)
        }
    }

    func toggleCamera() {
        if currentCamera == .front {
            cameraToggle.send(.rear)
            currentCamera = .rear
        }else {
            cameraToggle.send(.front)
            currentCamera = .front
        }
    }

    private func joinMessageChannel() async  {
        let token = await chatApi.fetch(userid:  Constants.shared.rtmUser)
        let login = await agoraRtm.login(byToken: token.value, user: Constants.shared.rtmUser)

        if login == .ok {
            createMessageChannel()
            let result = await rtmChannel?.join()
            print("joinMessageChannel", "success \(result?.rawValue ?? -1)" )
        } else {
            print("joinMessageChannel", "failure \(login)")
        }
    }

    private func createMessageChannel() {
        guard let rtmChannel = agoraRtm.createChannel(withId: Constants.shared.channel, delegate: self) else {
            alertSubject.send(.channelError)
            return
        }
        self.rtmChannel = rtmChannel
    }


    private func observeRtcLoginState() {
        let connection = isConnected.share()
        connection
            .filter { $0 == .connected }
            .sink { _ in
                self.alertSubject.send(.success)
                Task {
                    await self.joinMessageChannel()
                }
            }
            .store(in: &subscriptions)

        connection
            .filter { $0 == .disconnected}
            .sink { _ in
                self.agoraEngine.stopPreview()
            }
            .store(in: &subscriptions)
    }

    private func leaveChannel() {
        let result = agoraEngine.leaveChannel(nil)
        if result == 0 { self.isConnected.send(.disconnected) }
    }

    private func leaveMessageChannel() {
         rtmChannel?.leave { (error) in
             print("leave channel error:\(error.rawValue)")
         }
     }

}


extension LiveChatViewModel: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        newHostEvent.send(uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError")
    }

}


extension LiveChatViewModel : AgoraRtmDelegate {

    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        print("connectionStateChanged", state.rawValue)
        print("connectionStateChanged reason ", reason)

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
        print("messageReceived", message.text)
    }

}
