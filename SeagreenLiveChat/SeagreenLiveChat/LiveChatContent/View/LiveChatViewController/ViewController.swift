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

    lazy var localView: KitView = .init()
    lazy var remoteView: KitView = .init()
    lazy var decorator: ViewControllerDecorator = .init()
    var joinButton: UIButton!
    var subscriptions: Set<AnyCancellable> = .init()
    var viewModel: LiveChatViewModel

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.leaveChannels()
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
        viewModel.agoraEngine.enableVideo()
        viewModel.agoraEngine.startPreview()
        viewModel.agoraEngine.enableVideo()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        // Set the local video view
        viewModel.agoraEngine.setupLocalVideo(videoCanvas)
    }

    func handleCameraState(state : CameraPosition) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        if state == .front {
            self.localView.isHidden = false
            videoCanvas.view = self.localView
        } else{
            self.localView.isHidden = true
            videoCanvas.view = self.remoteView
        }
        // Set the local video view
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
                self.handleCameraState(state: state)
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
