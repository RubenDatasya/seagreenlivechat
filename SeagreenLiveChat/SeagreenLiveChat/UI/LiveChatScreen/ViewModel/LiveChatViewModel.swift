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

    var isParticipantSharing: Bool {
        get { sharedState.isSharing }
    }

    var showSharedCommand: Bool {
        get {isParticipantSharing || localCameraPosition == .rear}
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
    @Published var isSharing: Bool =  false
    @Published var hostState: HostState = .disconnected

    let cameraInput : CameraControlProtocol & ResetCameraControlProtocol = CameraInput()

    var isConnected:   PassthroughSubject<RTCLoginState, Never> = .init()
    var cameraToggle:  PassthroughSubject<CameraPosition, Never> = .init()
    var hostEvent:  PassthroughSubject<HostState, Never> = .init()
    var channelMessage : PassthroughSubject<ChannelMessageEvent, Never> = .init()

    var zoomIn:  PassthroughSubject<(), Never> = .init()
    var zoomOut:  PassthroughSubject<(), Never> = .init()
    var exposureUp:  PassthroughSubject<(), Never> = .init()
    var exposureDown:  PassthroughSubject<(), Never> = .init()
    var flashUp:  PassthroughSubject<(), Never> = .init()
    var flashDown:  PassthroughSubject<(), Never> = .init()

    var resetExposure: PassthroughSubject<(),Never> = .init()
    var resetZoom: PassthroughSubject<(),Never> = .init()
    var resetFocus: PassthroughSubject<(),Never> = .init()
    var resetFlash: PassthroughSubject<(),Never> = .init()


    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()
    var subscriptions: Set<AnyCancellable> = .init()


    func initializeAgora() {
        AgoraRtc.shared.initialize()
        AgoraRtc.shared.addDelegate(self)
        AgoraRtm.shared.initalize()
        AgoraRtm.shared.setDelegate(self)
        observeRtcLoginState()
    }

    private func observeRtcLoginState() {
        let connection = isConnected.share()
        connection
            .filter { $0 == .connected }
            .sink { _ in
                Task {
                    do {
                        try await AgoraRtm.shared.joinMessageChannel(delegate: self)
//                        try await self.chatRepository.createChat(with: .init(name: Constants.Credentials.channel, openedBy: Constants.Credentials.currentUser, peer: nil))
                    } catch {
                        Logger.severe("observeRtcLoginState",error: error)
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

    private func handleUnknownMessage(_ text: String) {
        if let point : CGPoint = JsonHandler.decode(text) {
            cameraInput.focus(at: point)
        }
    }


    private func handleState(_ event: ChannelMessageEvent, state: inout CameraState) {
        switch event {
        case .zoomIn:
            cameraInput.updateZoom(isIn: true)
        case .zoomOut:
            cameraInput.updateZoom(isIn: false)
        case .brightnessUp:
            cameraInput.updateExposure(isUp: true)
        case .brightnessDown:
            cameraInput.updateExposure(isUp: false)
        case .flash:
            cameraInput.updateFlash(isUp: true)
        case .flashDown:
            cameraInput.updateFlash(isUp: false)
        case .resetZoom:
            cameraInput.resetZoom()
        case .resetFlash:
            cameraInput.resetFlash()
        case .resetFocus:
            cameraInput.resetFocus()
        case .resetExposure:
            cameraInput.resetExposure()
        case .participantShares:
            state.isSharing = true
        case .participantStoppedSharring:
            state.isSharing = false
        case .leave:
            break
        default:
            Logger.info("handleState \(event) Not meant to be handled")
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
            localState.isSharing = true
            sendMessage(event: .participantShares)
        } else {
            localState.isSharing = false
            sendMessage(event: .participantStoppedSharring)
        }
    }
}

extension LiveChatViewModel: SendMessageProtocol {

    func sendMessage(event: ChannelMessageEvent) {
        AgoraRtm.shared.sendMessage(event: event)
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
        Logger.info("didOccurError AgoraErrorCode \(errorCode.rawValue)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        Logger.info("didOccur AgoraEncryptionErrorType \(errorType.rawValue)")
    }
}

extension LiveChatViewModel : AgoraRtmDelegate {

    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        Logger.info("didOccur connectionStateChanged, \(state)")
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        Logger.info("tokenPrivilegeWillExpire")
    }

    func rtmKitTokenDidExpire(_ kit: AgoraRtmKit) {
        Logger.info("rtmKitTokenDidExpire")
    }

}


extension LiveChatViewModel: AgoraRtmChannelDelegate {

    func channel(_ channel: AgoraRtmChannel, memberCount count: Int32) {
        Logger.info("memberCount, \(count)")
    }

    func channel(_ channel: AgoraRtmChannel, attributeUpdate attributes: [AgoraRtmChannelAttribute]) {
        Logger.info("attributeUpdate")
    }

    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        Logger.info("memberJoined join \(member.description)")

    }

    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        Logger.info("memberJoined left \(member.description)")
    }

    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        Logger.info("messageReceived \(message.text) from \(member.userId)")
        let event = ChannelMessageEvent.value(message.text)
        if event == ChannelMessageEvent.unknown {
            handleUnknownMessage(message.text)
        } else {
            handleState(event, state: &sharedState)
        }
    }

}
