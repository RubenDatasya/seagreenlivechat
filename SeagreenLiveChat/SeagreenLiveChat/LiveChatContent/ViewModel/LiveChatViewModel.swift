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
    var userRole: AgoraClientRole = .broadcaster

    lazy var chatApi = LiveChatTokenAPI()
    lazy var messsagingApi = SignalingTokenAPI()

    var agoraEngine: AgoraRtcEngineKit!
    var agoraRtm: AgoraRtmKit!
    var rtmChannel: AgoraRtmChannel?

    var subscriptions: Set<AnyCancellable> = .init()

    let metalDevice = MTLCreateSystemDefaultDevice()
    var metalCommandQueue: MTLCommandQueue?

    var encodingConfiguration = AgoraVideoEncoderConfiguration(
        size: .init(width: 640, height: 360),
        frameRate: .fps60,
        bitrate: AgoraVideoBitrateStandard,
        orientationMode: .adaptative,
        mirrorMode: .disabled)


    func initializeAgora(videoFrameDelegate : AgoraVideoFrameDelegate) {
        setupAgoraEngine(videoFrameDelegate: videoFrameDelegate)
        agoraRtm = .init(appId: Constants.Secret.appid, delegate: self)
        observeRtcLoginState()
        observeCameraState()
        metalCommandQueue = metalDevice?.makeCommandQueue()
    }

    func setupAgoraEngine(videoFrameDelegate : AgoraVideoFrameDelegate) {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.Secret.appid
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine.setVideoFrameDelegate(videoFrameDelegate)
        agoraEngine.setVideoEncoderConfiguration(encodingConfiguration)
        agoraEngine.setBeautyEffectOptions(true, options: nil)
        let enhancements : [any AgoraQualityImprovementProtocol] = [AgoraColorEnhancement(), AgoraUnderExposed(), AgoraVideoDenoising()]
        enhancements.forEach { improvement in
            agoraEngine.setExtensionPropertyWithVendor(improvement.name, extension: improvement.extension, key: improvement.key, value: improvement.value,sourceType: .remoteVideo)
        }
        agoraEngine.enableVideo()
        agoraEngine.startPreview()
    }

    func joinChannel() async  {
        let token = await chatApi.fetch(userid: Constants.Credentials.currentUser)

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
            byToken: Constants.Credentials.token, channelId: Constants.Credentials.channel, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in
            })
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
                self.agoraEngine.setCameraTorchOn(state.isFlashOn)
                self.agoraEngine.setCameraZoomFactor(state.zoom)
            }
            .store(in: &subscriptions)

        $localState
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.agoraEngine.setCameraTorchOn(state.isFlashOn)
                self.agoraEngine.setCameraZoomFactor(state.zoom)
            }
            .store(in: &subscriptions)
    }

    private func joinMessageChannel() async  {
        let token = await chatApi.fetch(userid:  Constants.Credentials.currentUser)

        let login = await agoraRtm.login(byToken: token.value, user: Constants.Credentials.currentUser)

        if login == .ok {
            createMessageChannel()
            let result = await rtmChannel?.join()
            print("joinMessageChannel", "success \(result?.rawValue ?? -1)" )
        } else {
            print("joinMessageChannel", "failure \(login)")
        }
    }

    private func createMessageChannel() {
        guard let rtmChannel = agoraRtm.createChannel(withId: Constants.Credentials.channel, delegate: self) else {
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
            if agoraEngine.isCameraTorchSupported() {
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
