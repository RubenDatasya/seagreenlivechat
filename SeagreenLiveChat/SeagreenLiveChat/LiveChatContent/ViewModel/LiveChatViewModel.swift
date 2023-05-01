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

class LiveChatViewModel: NSObject, ObservableObject {

    @Published var isConnected: Bool = false
    var currentCamera: CameraState = .front
    var cameraToggle:  PassthroughSubject<CameraState, Never> = .init()
    var alertSubject: PassthroughSubject<LiveChatAlert, Never> = .init()
    var setupEvent:  PassthroughSubject<Void, Never> = .init()
    var newHostEvent:  PassthroughSubject<UInt, Never> = .init()
    var messageEvent:  PassthroughSubject<ChannelMessage, Never> = .init()
    var userRole: AgoraClientRole = .broadcaster

    lazy var chatApi = LiveChatTokenAPI()
    lazy var messsagingApi = SignalingTokenAPI()

    var agoraEngine: AgoraRtcEngineKit!
    var agoraRtm: AgoraRtmKit!
    var rtmChannel: AgoraRtmChannel?


    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.shared.appId
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraRtm = .init(appId: Constants.shared.appId, delegate: self)
    }

    func joinChannel() async  {
        if await !AVPermissionManager.shared.checkForPermissions() {
            alertSubject.send(.permissionError)
            return
        }

        let option = AgoraRtcChannelMediaOptions()
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
            setupEvent.send(())
        } else {
            option.clientRoleType = .audience
        }
        option.channelProfile = .communication

        let token = await chatApi.fetch(userid:  Constants.shared.currentUser)

         let result = agoraEngine.joinChannel(
            byToken: token.value, channelId: Constants.shared.channel, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in }
        )
         if result == 0 {
            DispatchQueue.main.async {
                self.isConnected =  true
            }
            alertSubject.send(.success)
        }
    }

    func joinMessageChannel() async  {
       // let token = await messsagingApi.fetch(userid:  Constants.shared.currentUser)
        //fake token above
        print(Constants.shared.currentUser)
        let login = await agoraRtm.login(byToken: nil, user: Constants.shared.currentUser)
        if login == .ok {
            createMessageChannel()
            let result = await rtmChannel?.join()
            print("joinMessageChannel", "\(result?.rawValue ?? -1)" )
        }
        print("joinMessageChannel", "login \(login)")
    }

    func createMessageChannel() {
        guard let rtmChannel = agoraRtm.createChannel(withId: Constants.shared.channel, delegate: self) else {
            alertSubject.send(.channelError)
            return
        }
        self.rtmChannel = rtmChannel
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

    private func leaveChannel() {
        agoraEngine.stopPreview()
        let result = agoraEngine.leaveChannel(nil)
        if result == 0 { self.isConnected = false }
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

}


extension LiveChatViewModel : AgoraRtmDelegate {

    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        print("connectionStateChanged", state.rawValue)
        print("connectionStateChanged reason ", reason)

    }

    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        print("rtmkit", "nessage received from \(peerId)")
        print("rtmkit", "nessage \(message)")
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
        print("\(message)")
    }

}
