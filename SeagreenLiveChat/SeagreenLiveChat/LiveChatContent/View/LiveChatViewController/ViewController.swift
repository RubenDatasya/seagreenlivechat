//
//  ViewController.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

import Foundation
import AVFoundation
import Combine
#if os(iOS)
import UIKit
#else
import AppKit
#endif
import AgoraRtcKit
import AgoraRtmKit
import SwiftUI

#if os(iOS)
typealias KitView = UIView
#else
typealias KitView = NSView
#endif

struct VideoChat: UIViewControllerRepresentable {

    @ObservedObject var viewModel: LiveChatViewModel

    func makeUIViewController(context: Context) -> ViewController {
        let vc = ViewController(viewModel: viewModel)
        return vc
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {

    }

    typealias UIViewControllerType = ViewController
}


class ViewController: UIViewController {

    lazy var localView: UIView = .init()
    lazy var remoteView: UIView = .init()
    lazy var decorator: ViewControllerDecorator = .init()
    var joinButton: UIButton!
    var subscriptions: Set<AnyCancellable> = .init()
    var viewModel: LiveChatViewModel

 //   lazy var customCamera = AgoraCameraSourcePush(delegate: self, videoView: localView)


    init(viewModel: LiveChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
         super.viewDidLoad()
        initViews()
        observeAlert()
        observeNewHost()
        observeCamera()
        observeChannelMessages()
        viewModel.initializeAgoraEngine()
        setupLocalVideo()
        joinChannels()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.agoraEngine.setVideoFrameDelegate(self)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.leaveChannels()
        viewModel.agoraEngine.setVideoFrameDelegate(nil)
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
    }

    func initViews() {
        self.view.backgroundColor = .systemPurple
        self.view.addSubview(remoteView)
        self.view.addSubview(localView)
        view.bringSubviewToFront(localView)
        localView.hide()
        decorator.decorate(localView: localView, in: self.view)
        decorator.decorate(remoteView: remoteView, in: self.view)
    }

    func setupLocalVideo() {
        localView.animate { view in
            view.show()
        }

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        // Set the local video view
        viewModel.agoraEngine.setupLocalVideo(videoCanvas)
      //  customCamera.startCapture(ofCamera: .front)

    }

    func handleCameraState() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        if viewModel.state.position == .front {
            self.localView.isHidden = false
            videoCanvas.view = self.localView
        } else{
            self.localView.isHidden = true
            videoCanvas.view = self.remoteView
        }
        self.viewModel.agoraEngine.setupLocalVideo(videoCanvas)
    }


    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alert.addAction(.init(title: "Ok", style: .default, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
        })
    }

    func joinChannels() {
        Task {
            await viewModel.joinChannel()
        }
    }

    private func handleChannelMessageEvent( _ event: ChannelMessageEvent) {    }
}

extension ViewController {

    func observeAlert() {
        viewModel.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { alert in
                self.showMessage(title: alert.title, text: alert.text)
            }
            .store(in: &subscriptions)
    }

    func observeCamera() {
        viewModel.cameraToggle
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.viewModel.agoraEngine.switchCamera()
                self.handleCameraState()
            }
            .store(in: &subscriptions)
    }

    func observeNewHost() {
        viewModel.newHostEvent
            .receive(on: DispatchQueue.main)
            .sink { (uid) in
                print(UIDevice.current.systemName, "installing remote canvas for \(uid)")
                let videoCanvas = AgoraRtcVideoCanvas()
                videoCanvas.uid = uid
                videoCanvas.renderMode = .hidden
                videoCanvas.view = self.remoteView
                self.viewModel.agoraEngine.setupRemoteVideo(videoCanvas)
            }
            .store(in: &subscriptions)
    }

    func observeChannelMessages() {
        viewModel.receivedMessage
            .filter { $0  != .unknown }
            .sink(receiveValue: handleChannelMessageEvent(_:))
            .store(in: &subscriptions)
    }

}


extension ViewController: AgoraVideoFrameDelegate {
    // Occurs each time the SDK receives a video frame captured by the local camera
    func onCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {

        return true
    }

    // Occurs each time the SDK receives a video frame captured by the screen
    func onScreenCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        // Choose whether to ignore the current video frame if the pre-processing fails
        return false
    }

    // Occurs each time the SDK receives a video frame sent by the remote user
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        // Choose whether to ignore the current video frame if the post-processing fails
        return false
    }

    // Indicate the video frame mode of the observer
    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        // The process mode of the video frame: readOnly, readWrite
        return AgoraVideoFrameProcessMode.readWrite
    }

    // Sets the video frame type preference
    func getVideoFormatPreference() -> AgoraVideoFormat {
        // Video frame format: I420, BGRA, NV21, RGBA, NV12, CVPixel, I422, Default
        return AgoraVideoFormat.RGBA
    }

    // Sets the frame position for the video observer
    func getObservedFramePosition() -> AgoraVideoFramePosition {
        // Frame position: postCapture, preRenderer, preEncoder
        return AgoraVideoFramePosition.postCapture
    }
}
