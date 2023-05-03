//
//  ViewController.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

import Foundation
import AVFoundation
import Combine
import UIKit
import AgoraRtcKit
import AgoraRtmKit
import SwiftUI


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
    lazy var remoteVideo: MetalVideoView = Bundle.loadView(fromNib: "VideoViewMetal", withType: MetalVideoView.self)
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
        viewModel.initializeAgora(videoFrameDelegate: remoteVideo.videoView)
        remoteVideo.liveChatViewModel = viewModel
        joinChannels()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLocalVideo()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.leaveChannels()
        viewModel.agoraEngine.setVideoFrameDelegate(nil)
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
    }

    func initViews() {
        self.view.backgroundColor = .systemPurple
        self.view.addSubview(remoteVideo)
        self.view.addSubview(localView)
        view.bringSubviewToFront(localView)
        decorator.decorate(localView: localView, in: self.view)
        decorator.decorate(remoteView: remoteVideo, in: self.view)
    }

    func setupLocalVideo() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        viewModel.agoraEngine.setupLocalVideo(videoCanvas)
        localView.animate(delay: 1.5) { view in
            view.transform = CGAffineTransform(scaleX: 1, y: 1)
            view.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }

    func handleCameraState() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        if viewModel.localState.position == .front {
            self.localView.isHidden = false
            videoCanvas.view = self.localView
        } else{
            self.localView.isHidden = true
            videoCanvas.view = self.remoteVideo
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

    private func handleHostingState( _ state: HostState) {
        switch state {
        case .received(let uid):
            remoteVideo.animate { view in
                self.remoteVideo.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            remoteVideo.videoView.startRender(uid: uid)
        case .disconnected(let uid), .none(let uid):
            remoteVideo.animate { view in
                view.transform = CGAffineTransform(scaleX: 0, y: 0)
            }
            remoteVideo.videoView.stopRender(uid: uid)
        }
    }
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
        viewModel.hostEvent
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handleHostingState(_:))
            .store(in: &subscriptions)
    }
}


