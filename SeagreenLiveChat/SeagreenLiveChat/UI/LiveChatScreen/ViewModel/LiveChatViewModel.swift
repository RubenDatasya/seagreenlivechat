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

protocol LiveChatStateProtocol {
    var localState: CameraState { get set }
    var sharedState: CameraState { get set }
}

extension LiveChatStateProtocol {
    var localCameraPosition: CameraPosition {
        get { localState.position }
        set { localState.position = newValue }
    }
}

protocol LiveChatControlProtocol {
    func joinChannel() async
    func leaveChannels()
    func toggleCamera()
    func toggleAudio()
}

protocol SendMessageProtocol {
    func sendMessage(event: ChannelMessageEvent)
}

class LiveChatViewModel: NSObject, ObservableObject, LiveChatStateProtocol {

    @Published var localState: CameraState = .init(position: .front)
    @Published var sharedState: CameraState = .init(position: .front)
    @Published var hostState: HostState = .disconnected

    var cameraInput : CameraControlProtocol = CameraInput()
    var isConnected:   PassthroughSubject<RTCLoginState, Never> = .init()
    var cameraToggle:  PassthroughSubject<CameraPosition, Never> = .init()
    var hostEvent:  PassthroughSubject<HostState, Never> = .init()
    var zoomIn:  PassthroughSubject<(), Never> = .init()
    var zoomOut:  PassthroughSubject<(), Never> = .init()
    var exposureUp:  PassthroughSubject<(), Never> = .init()
    var exposureDown:  PassthroughSubject<(), Never> = .init()
    var flashUp:  PassthroughSubject<(), Never> = .init()
    var flashDown:  PassthroughSubject<(), Never> = .init()
    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()

    lazy var chatApi = LiveChatTokenAPI()
    lazy var messsagingApi = SignalingTokenAPI()

    var subscriptions: Set<AnyCancellable> = .init()


    func initializeAgora() {
        AgoraRtc.shared.initialize()
        AgoraRtc.shared.addDelegate(self)
        AgoraRtm.shared.initalize()
        AgoraRtm.shared.setDelegate(self)
        observeRtcLoginState()
        observeCameraState()
    }

    private func observeCameraState() {
        $sharedState
            .receive(on: DispatchQueue.main)
            .sink { state in
                AgoraRtc.shared.activate(state: state)
            }
            .store(in: &subscriptions)

        $localState
            .receive(on: DispatchQueue.main)
            .sink { state in
                AgoraRtc.shared.activate(state: state)
            }
            .store(in: &subscriptions)
    }

    private func observeRtcLoginState() {
        let connection = isConnected.share()
        connection
            .filter { $0 == .connected }
            .sink { _ in
                Task {
                    do {
                        try await AgoraRtm.shared.joinMessageChannel(delegate: self)
                    } catch {
                        print("observeRtcLoginState", error)
                    }
                }
            }
            .store(in: &subscriptions)

        connection
            .filter { $0 == .disconnected}
            .sink { _ in
                AgoraRtc.shared.stop()
            }
            .store(in: &subscriptions)
    }

    private func handleSharedState(_ event: ChannelMessageEvent) {
        handleState(event, state: &sharedState)
    }


    private func handleState(_ event: ChannelMessageEvent) {
        handleState(event, state: &localState)
    }

    private func handleUnknownMessage(_ text: String) {
        print("handlingUnknown",text )
        if let point : CGPoint = JsonHandler.decode(text) {
            cameraInput.focus(at: point)
        }
    }


    private func handleState(_ event: ChannelMessageEvent, state: inout CameraState) {
        switch event {
        case .zoomIn:
            zoomIn.send(())
        case .zoomOut:
            zoomOut.send(())
        case .brightnessUp:
            exposureUp.send(())
        case .brightnessDown:
            exposureDown.send(())
        case .flash:
            flashUp.send(())
        case .flashDown:
            flashDown.send(())
        case .participantShares, .participantStoppedSharring :
            state.position = .front
        case .leave:
            break
        case .focus:
            break
        default:
            print(event,"Not meant to be handled")
        }
    }
}

extension LiveChatViewModel: LiveChatControlProtocol {

    func joinChannel() async  {
        do {
            let result = try await AgoraRtc.shared.joinChannel()
            self.isConnected.send(result)
        } catch {
            if let liveAlert = error as? LiveChatAlert {
                self.alertSubject.send(liveAlert)
            }
        }
    }

    func toggleAudio() {
        AgoraRtc.shared.toggleAudio()
    }

    func leaveChannels() {
        AgoraRtc.shared.leaveChannel()
        AgoraRtm.shared.leaveChannel()
    }

    func toggleCamera() {
        localState.inverse()
        cameraInput.switchCameraInput()
        cameraToggle.send(localState.position)
        if localState.position == .rear {
            localState.zoom = 0
        }
    }
}

extension LiveChatViewModel: SendMessageProtocol {

    func sendMessage(event: ChannelMessageEvent) {
        AgoraRtm.shared.sendMessage(event: event)
        handleState(event)
    }

}

extension LiveChatViewModel: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        hostState = .received(uid: uid)
        hostEvent.send(.received(uid: uid))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        hostState = .disconnected
        hostEvent.send(.disconnected)
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
        let event = ChannelMessageEvent.value(message.text)
        if event == ChannelMessageEvent.unknown {
            handleUnknownMessage(message.text)
        } else {
            handleSharedState(event)
        }
    }

}
