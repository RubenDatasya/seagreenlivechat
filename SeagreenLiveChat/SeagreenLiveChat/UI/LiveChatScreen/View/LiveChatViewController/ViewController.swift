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
        let vc: ViewController = .init(nibName: nil, bundle: nil)
        vc.viewModel = viewModel
        return vc
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {

    }

    typealias UIViewControllerType = ViewController
}

class ViewController: UIViewController {

    lazy var remoteView: UIView = UIView()
    var localView: CustomVideoSourcePreview = .init()
    var cameraInput = CameraInput()

    lazy var decorator: ViewControllerDecorator = .init()
    var joinButton: UIButton!
    var subscriptions: Set<AnyCancellable> = .init()
    var viewModel: LiveChatViewModel!


    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.initializeAgora()
        initViews()
        observeAlert()
        observeNewHost()
        observeCamera()
        observeZoom()
        observeFlash()
        observeExposure()
        joinChannels()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AgoraRtc.shared.start()
        AgoraRtc.shared.setupLocalVideo(localView)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.leaveChannels()
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
    }

    func initViews() {
        self.view.backgroundColor = UIColor(Colors.transparentGray)
        self.view.addSubview(remoteView)
        self.view.addSubview(localView)
        cameraInput.setup(position: .front, locaPreview: localView)
        decorator.decorate(localView: localView, in: self.view)
        decorator.decorate(remoteView: remoteView, in: self.view)
    }

    func handleCameraState(state: CameraPosition) {
        self.localView.translatesAutoresizingMaskIntoConstraints = true
        if state == .rear {
            UIView.animate(withDuration: 0.5) {
                self.localView.frame = CGRect(origin: .zero, size: .init(width: self.view.frame.size.width, height: self.view.frame.size.height))
            }
            DispatchQueue.main.async {
                self.cameraInput.switchCameraInput()
            }
        } else {
            decorator.decorate(localView: localView, in: self.view)
        }
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
            AgoraRtc.shared.setupRemoteVideo(remoteView, uid: uid)
        case .disconnected(let uid), .none(let uid):
            AgoraRtc.shared.setupRemoteVideo(.init(), uid: uid)
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
            .sink(receiveValue: handleCameraState(state:))
            .store(in: &subscriptions)
    }

    func observeNewHost() {
        viewModel.hostEvent
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handleHostingState(_:))
            .store(in: &subscriptions)
    }

    func observeZoom() {
        viewModel.zoomIn
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateZoom(isIn: true)
            }
            .store(in: &subscriptions)

        viewModel.zoomOut
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateZoom(isIn: false)
            }
            .store(in: &subscriptions)
    }

    func observeFlash() {
        viewModel.flashUp
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateFlash(isUp: true)
            }
            .store(in: &subscriptions)

        viewModel.flashDown
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateFlash(isUp: false)
            }
            .store(in: &subscriptions)
    }

    func observeExposure() {
        viewModel.exposureUp
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateExposure(isUp: true)
            }
            .store(in: &subscriptions)

        viewModel.exposureDown
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.cameraInput.updateExposure(isUp: false)
            }
            .store(in: &subscriptions)
    }
}
