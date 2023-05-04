//
//  AgoraRtc.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 04/05/2023.
//

import Foundation
import AgoraRtcKit

class AgoraRtc: NSObject {

    var agoraEngine: AgoraRtcEngineKit! {
        didSet {
            kit = agoraEngine
        }
    }

    private (set) var kit: AgoraRtcEngineKit!

    private var userRole: AgoraClientRole = .broadcaster


    private var encodingConfiguration = AgoraVideoEncoderConfiguration(
        size: AgoraVideoDimension1280x720,
        frameRate: .fps60,
        bitrate: AgoraVideoBitrateStandard,
        orientationMode: .adaptative,
        mirrorMode: .disabled)

    static let shared = AgoraRtc()

    lazy var chatApi = LiveChatTokenAPI()

    private override init() {}

    func initialize() {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.Secret.appid
        config.channelProfile = .liveBroadcasting
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: nil)
    }

    func addDelegate(_ delegate : AgoraRtcEngineDelegate) {
        agoraEngine.delegate = delegate
        agoraEngine.setVideoFrameDelegate(AgoraMetalRender())
    }

    func pushFrame(_ frame: AgoraVideoFrame) {
        guard let agoraEngine = agoraEngine else {
            fatalError("Agora engine not initialized")
        }
        agoraEngine.pushExternalVideoFrame(frame)
    }

    func start() {
        agoraEngine.enableVideo()
        agoraEngine.setExternalVideoSource(true, useTexture: true, sourceType: .videoFrame)
        agoraEngine.setVideoEncoderConfiguration(encodingConfiguration)
        agoraEngine.enableMultiCamera(true, config: nil)
        agoraEngine.setEncodedVideoFrameDelegate(self)
    }

    func setupLocalVideo(_ view: UIView){
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.sourceType = .custom
        videoCanvas.view = view
        agoraEngine.setupLocalVideo(videoCanvas)
    }

    func setupRemoteVideo(_ view: UIView, uid: UInt){
        view.backgroundColor = .red
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.sourceType = .remote
        videoCanvas.view = view
        let setup = agoraEngine.setupRemoteVideo(videoCanvas)
        print("setupRemoteVideo",setup)
    }

    func joinChannel() async throws -> RTCLoginState {
        let token = await chatApi.fetch(userid: Constants.Credentials.currentUser)

        if await !AVPermissionManager.shared.checkForPermissions() {
            throw LiveChatAlert.permissionError
        }

        let option = AgoraRtcChannelMediaOptions()
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
        } else {
            option.clientRoleType = .audience
        }
        option.channelProfile = .liveBroadcasting

         let result = agoraEngine.joinChannel(
            byToken: Constants.Credentials.token, channelId: Constants.Credentials.channel, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in
            })
         if result == 0 {
             return .connected
         } else {
             return .failureConnecting
         }
    }

    func activate(state: CameraState) {
        self.agoraEngine.setCameraTorchOn(state.isFlashOn)
        self.agoraEngine.setCameraZoomFactor(state.zoom)
    }

    func stop() {
        agoraEngine.stopPreview()
    }

    @discardableResult
    func leaveChannel() -> Bool {
        let result = agoraEngine.leaveChannel(nil)
        return result == 0
    }

    private func improveCapture() {
        agoraEngine.setBeautyEffectOptions(true, options: nil)
        let enhancements : [any AgoraQualityImprovementProtocol] = [AgoraColorEnhancement(), AgoraUnderExposed(), AgoraVideoDenoising()]
        enhancements.forEach { improvement in
            agoraEngine.setExtensionPropertyWithVendor(improvement.name, extension: improvement.extension, key: improvement.key, value: improvement.value,sourceType: .remoteVideo)
        }
    }
}

extension AgoraRtc: AgoraEncodedVideoFrameDelegate {

    func onEncodedVideoFrameReceived(_ videoData: Data, length: Int, info videoFrameInfo: AgoraEncodedVideoFrameInfo) -> Bool {
        print("Camera", "frame is encoded")
        print("videoFrameInfo", videoFrameInfo)
        return true
    }
}
