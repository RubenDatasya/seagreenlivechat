//
//  AgoraRtc.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 04/05/2023.
//

import Foundation
import AgoraRtcKit

class AgoraRtc: NSObject {

    var agoraEngine: AgoraRtcEngineKit!

    private var userRole: AgoraClientRole = .broadcaster

    private var encodingConfiguration = AgoraVideoEncoderConfiguration(
        size: AgoraVideoDimension1280x720,
        frameRate: .fps60,
        bitrate: AgoraVideoBitrateStandard,
        orientationMode: .adaptative,
        mirrorMode: .disabled)

    static let shared = AgoraRtc()

    lazy var tokenRepository = AgoraTokenRepository()

    private var audioEnabled: Bool = true

    private override init() {}

    func initialize() {
        let config = AgoraRtcEngineConfig()
        let logConfig = AgoraLogConfig()
        let logFilePath = "\(FileManager().currentDirectoryPath)/logs.log"
        logConfig.filePath = logFilePath
        logConfig.fileSizeInKB = 2 * 1024
        config.logConfig = logConfig
        config.appId = Constants.Secret.appid
        config.channelProfile = .liveBroadcasting
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: nil)
    }

    func addDelegate(_ delegate : AgoraRtcEngineDelegate) {
        agoraEngine.delegate = delegate
    }

    func pushFrame(_ frame: AgoraVideoFrame) {
        guard agoraEngine != nil else {
            fatalError("Agora engine not initialized")
        }
        self.agoraEngine.pushExternalVideoFrame(frame)
    }

    func start() {
        agoraEngine.enableVideo()
        agoraEngine.setExternalVideoSource(true, useTexture: true, sourceType: .videoFrame)
        agoraEngine.setVideoEncoderConfiguration(encodingConfiguration)
    }

    func setupLocalVideo(_ view: UIView){
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = view
        agoraEngine.setupLocalVideo(videoCanvas)
    }

    func setupRemoteVideo(_ view: UIView, uid: UInt){
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = view
        agoraEngine.setupRemoteVideo(videoCanvas)
    }

    func joinChannel() async throws -> RTCLoginState {
        let token = try await tokenRepository.getRtcToken(with: Constants.Credentials.channel, uid: 0)

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
            byToken: token.value, channelId: Constants.Credentials.channel, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in
            })
         if result == 0 {
             return .connected
         } else {
             return .failureConnecting
         }
    }

    func toggleAudio() {
        if audioEnabled {
            agoraEngine.disableAudio()
        }else {
            agoraEngine.enableAudio()
        }
    }
    func stop() {
        agoraEngine.stopPreview()
    }

    func destroy() {
        AgoraRtcEngineKit.destroy()
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
