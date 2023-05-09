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
    var hostState: HostState { get set }
}

extension LiveChatStateProtocol {
    var localCameraPosition: CameraPosition {
        get { localState.position }
        set { localState.position = newValue }
    }

    var isLiveStreaming: Bool {
        get { localState.position == .rear && hostState.isConnected  }
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

    @Published var localState : CameraState = .init(position: .front)
    @Published var sharedState: CameraState = .init(position: .front)
    @Published var hostState  : HostState   = .disconnected

    var cameraInput : CameraControlProtocol = CameraInput()
    var isConnected :   PassthroughSubject<RTCLoginState, Never> = .init()
    var cameraToggle:  PassthroughSubject<CameraPosition, Never> = .init()
    var hostEvent   :  PassthroughSubject<HostState, Never> = .init()
    var zoomIn      :  PassthroughSubject<(), Never> = .init()
    var zoomOut     :  PassthroughSubject<(), Never> = .init()
    var exposureUp  :  PassthroughSubject<(), Never> = .init()
    var exposureDown:  PassthroughSubject<(), Never> = .init()
    var flashUp     :  PassthroughSubject<(), Never> = .init()
    var flashDown   :  PassthroughSubject<(), Never> = .init()
    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()

    lazy var chatApi = LiveChatTokenAPI()
    lazy var messsagingApi = SignalingTokenAPI()

    var subscriptions: Set<AnyCancellable> = .init()

    override init() {
        super.init()
        initializeAgora()
    }


    func initializeAgora() {
        AgoraRtc.shared.initialize()
        AgoraRtc.shared.addDelegate(self)
        AgoraRtm.shared.initalize()
        AgoraRtm.shared.setDelegate(self)
        observeRtcLoginState()
        observeCameraState()
    }

}

private extension LiveChatViewModel {
    func observeCameraState() {
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

    func observeRtcLoginState() {
        let connection = isConnected.share()
        connection
            .filter { $0 == .connected }
            .sink { _ in
                Task {
                    do {
                        try await AgoraRtm.shared.joinMessageChannel(delegate: self)
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

    func handleSharedState(_ event: ChannelMessageEvent) {
        handleState(event, state: &sharedState)
    }


    func handleState(_ event: ChannelMessageEvent) {
        handleState(event, state: &localState)
    }

    func handleUnknownMessage(_ text: String) {
        if let point : CGPoint = JsonHandler.decode(text) {
            cameraInput.focus(at: point)
        }
    }


    func handleState(_ event: ChannelMessageEvent, state: inout CameraState) {
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
            handleSharedState(event)
        }
    }

}
