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

enum CameraPosition {
    case rear
    case front
}

enum RTCLoginState {
    case disconnected
    case connecting
    case connected
    case failureConnecting
}

struct CameraState {
    var position: CameraPosition
    var zoom: CGFloat = 0.0
    var isFlashOn: Bool = false
}

class LiveChatViewModel: NSObject, ObservableObject {

    @Published var state: CameraState = .init(position: .front)
    var receivedMessage: PassthroughSubject<ChannelMessageEvent,Never> = .init()
    var isConnected:   PassthroughSubject<RTCLoginState, Never> = .init()
    var currentCamera: CameraPosition = .front
    var cameraToggle:  PassthroughSubject<CameraPosition, Never> = .init()
    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()
    var newHostEvent:  PassthroughSubject<UInt, Never> = .init()
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
        observeCameraState()
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
            joinSuccess: { (channel, uid, elapsed) in
            })
         if result == 0 {
             self.isConnected.send(.connected)
        }
    }

    func leaveChannels() {
//        leaveChannel()
//        leaveMessageChannel()
    }

    func sendMessage(event: ChannelMessageEvent) {
        self.rtmChannel?.send(AgoraRtmMessage(text: event.rawValue )){ error in
            print("sendMessage \(error)", error.rawValue)
        }
    }

    func toggleCamera() {
        if state.position == .front {
            cameraToggle.send(.rear)
            state.position = .rear
        }else {
            cameraToggle.send(.front)
            state.position = .front
        }
    }

    private func observeCameraState() {
        $state
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.agoraEngine.setCameraTorchOn(state.isFlashOn)
                self.agoraEngine.setCameraZoomFactor(state.zoom)
            }
            .store(in: &subscriptions)
    }

    private func joinMessageChannel() async  {
        let token = await chatApi.fetch(userid:  Constants.shared.currentUser)

        let login = await agoraRtm.login(byToken: token.value, user: Constants.shared.currentUser)

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
        print("didOccurError AgoraErrorCode", errorCode.rawValue)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        print("didOccur AgoraEncryptionErrorType", errorType.rawValue)
    }

}


extension LiveChatViewModel : AgoraRtmDelegate {

    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        print("connectionStateChanged", "\(state) \(state.rawValue)")
        print("connectionStateChanged", "\(reason) \(reason.rawValue)")


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
        if member.userId != Constants.shared.rtmUser {
            receivedMessage.send(ChannelMessageEvent.value(message.text))
        }

        switch ChannelMessageEvent.value(message.text) {
        case .zoomIn:
            if state.zoom < 1 {
                state.zoom += 0.1
            }
        case .zoomOut:
            if state.zoom > 0 {
                state.zoom -= 0.1
            }
        case .brightnessUp:
            break
        case .brightnessDown:
            break
        case .flashOn:
            if agoraEngine.isCameraTorchSupported() {
                state.isFlashOn =  true
            }
        case .flashOff:
            state.isFlashOn =  true
        case .leave:
            break
        case .unknown:
            break
        }
    }

}
