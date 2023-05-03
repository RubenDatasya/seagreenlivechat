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
import MetalKit

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
    var brightness: Float = 0.5
}


class LiveChatViewModel: NSObject, ObservableObject {

    @Published var localState: CameraState = .init(position: .front)
    @Published var sharedState: CameraState = .init(position: .front)
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

    let metalDevice = MTLCreateSystemDefaultDevice()
    var metalCommandQueue: MTLCommandQueue?

    var encodingConfiguration = AgoraVideoEncoderConfiguration(
        size: .init(width: 640, height: 360),
        frameRate: .fps60,
        bitrate: AgoraVideoBitrateStandard,
        orientationMode: .adaptative,
        mirrorMode: .disabled)



    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.Secret.appid
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine.setVideoFrameDelegate(self)
        upgradeCamera()
        agoraEngine.enableVideo()
        agoraEngine.startPreview()
        agoraRtm = .init(appId: Constants.Secret.appid, delegate: self)
        observeRtcLoginState()
        observeCameraState()
        metalCommandQueue = metalDevice?.makeCommandQueue()
    }

    func upgradeCamera() {
        agoraEngine.setVideoEncoderConfiguration(encodingConfiguration)
        agoraEngine.setBeautyEffectOptions(true, options: nil)
        let enhancements : [any AgoraQualityImprovementProtocol] = [AgoraColorEnhancement(), AgoraUnderExposed(), AgoraVideoDenoising()]
        enhancements.forEach { improvement in
            agoraEngine.setExtensionPropertyWithVendor(improvement.name, extension: improvement.extension, key: improvement.key, value: improvement.value,sourceType: .remoteVideo)
        }
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


    private func handleState(_ event: ChannelMessageEvent) {
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

    func createTexture(width: Int, height: Int, data: UnsafeRawPointer, stride: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width, height: height, mipmapped: false)
        let texture = metalDevice?.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: stride)
        return texture
    }

    func brightnessKernelFunction(device: MTLDevice) -> MTLComputePipelineState? {
        guard let metalDevice = metalDevice else { return nil }
        let defaultLibrary = try! metalDevice.makeDefaultLibrary(bundle: Bundle.main)
        let kernelFunction = defaultLibrary.makeFunction(name: "brightnessKernel")
        return try? device.makeComputePipelineState(function: kernelFunction!)
    }

    func applyComputeKernel(kernel: MTLComputePipelineState, width: Int, height: Int, groups: Int) {
        let commandBuffer = metalCommandQueue?.makeCommandBuffer()!
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()!
        commandEncoder?.setComputePipelineState(kernel)
        commandEncoder?.dispatchThreadgroups(MTLSizeMake(groups, (height + 15) / 16, 1), threadsPerThreadgroup: MTLSizeMake(16, 16, 1))
        commandEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
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
        if member.userId != Constants.Credentials.rtmUser {
            receivedMessage.send(ChannelMessageEvent.value(message.text))
        }
        handleState(ChannelMessageEvent.value(message.text))
    }

}

extension LiveChatViewModel: AgoraVideoFrameDelegate {
    // Occurs each time the SDK receives a video frame captured by the local camera
    func onCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
      //  print("onCapture")
        return true
    }

    // Occurs each time the SDK receives a video frame captured by the screen
    func onScreenCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        // Choose whether to ignore the current video frame if the pre-processing fails
        return false
    }
    // Occurs each time the SDK receives a video frame sent by the remote user
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        // Get the pixel buffer from the AgoraOutputVideoFrame
        guard let pixelBuffer = videoFrame.pixelBuffer else {
            return true
        }

        // Lock the pixel buffer to make it accessible in memory
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        // Get the image information from the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerPixel = 4
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Calculate the brightness adjustment factor
        let brightness: Float = localState.brightness

        // Modify the pixel buffer data to adjust the brightness
        for y in 0..<height {
            let row = baseAddress! + y * bytesPerRow
            for x in 0..<width {
                let pixel = row.advanced(by: x * bytesPerPixel).assumingMemoryBound(to: UInt8.self)

                // Convert the pixel values to floats between 0 and 1
                let red = Float(pixel[0]) / 255.0
                let green = Float(pixel[1]) / 255.0
                let blue = Float(pixel[2]) / 255.0

                // Apply the brightness adjustment factor
                let adjustedRed = min(max(red * brightness, 0), 1)
                let adjustedGreen = min(max(green * brightness, 0), 1)
                let adjustedBlue = min(max(blue * brightness, 0), 1)

                // Convert the adjusted pixel values back to UInt8 format
                pixel[0] = UInt8(adjustedRed * 255.0)
                pixel[1] = UInt8(adjustedGreen * 255.0)
                pixel[2] = UInt8(adjustedBlue * 255.0)
            }
        }


        // Unlock the pixel buffer to release the memory lock
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        videoFrame.pixelBuffer = pixelBuffer
        return true
    }


    // Indicate the video frame mode of the observer
    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        // The process mode of the video frame: readOnly, readWrite
        return AgoraVideoFrameProcessMode.readWrite
    }

    // Sets the video frame type preference
    func getVideoFormatPreference() -> AgoraVideoFormat {
        // Video frame format: I420, BGRA, NV21, RGBA, NV12, CVPixel, I422, Default
        return AgoraVideoFormat.cvPixelBGRA
    }

    // Sets the frame position for the video observer
    func getObservedFramePosition() -> AgoraVideoFramePosition {
        // Frame position: postCapture, preRenderer, preEncoder
        return AgoraVideoFramePosition.preRenderer
    }
}
