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

class LiveChatViewModel: NSObject, ObservableObject {

    @Published var localState: CameraState = .init(position: .front)
    @Published var sharedState: CameraState = .init(position: .front)
    var receivedMessage: PassthroughSubject<ChannelMessageEvent,Never> = .init()
    var isConnected:   PassthroughSubject<RTCLoginState, Never> = .init()
    var currentCamera: CameraPosition = .front
    var cameraToggle:  PassthroughSubject<CameraPosition, Never> = .init()
    var alertSubject:  PassthroughSubject<LiveChatAlert, Never> = .init()
    var hostEvent:  PassthroughSubject<HostState, Never> = .init()
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

    func leaveChannels() {
        AgoraRtc.shared.leaveChannel()
        AgoraRtm.shared.leaveChannel()
    }

    func sendMessage(event: ChannelMessageEvent) {
        AgoraRtm.shared.sendMessage(event: event)
        handleState(event)
    }

    func toggleCamera() {
        if localState.position == .front {
            localState.position = .rear
            cameraToggle.send(.rear)
            sendMessage(event: .participantShares)
        }else {
            localState.zoom = 0
            localState.position = .front
            cameraToggle.send(.front)
            sendMessage(event: .participantStoppedSharring)
        }
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



    func handleState(_ event: ChannelMessageEvent) {
        let isLocal = localState.position == .front && sharedState.position == .rear ||
                        localState.position == .front && sharedState.position == .front
        if isLocal {
            handleState(event, state: &localState)
        }else {
            handleState(event, state: &sharedState)
        }
    }


    private func handleState(_ event: ChannelMessageEvent, state: inout CameraState) {
        switch event {
        case .zoomIn:
            if state.zoom < 5 {
                state.zoom += 1
            }
        case .zoomOut:
            state.zoom -= 1
        case .brightnessUp:
            state.brightness += 0.1
        case .brightnessDown:
            break
        case .flash:
            if AgoraRtc.shared.agoraEngine.isCameraTorchSupported() {
                state.isFlashOn.toggle()
            }
        case .participantShares, .participantStoppedSharring :
            state.position = .front
        case .leave:
            break
        case .unknown:
            break
        }
    }
}

extension LiveChatViewModel: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        hostEvent.send(.received(uid: uid))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        hostEvent.send(.disconnected(uid: uid))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError AgoraErrorCode", errorCode.rawValue)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        print("didOccur AgoraEncryptionErrorType", errorType.rawValue)
    }
}
