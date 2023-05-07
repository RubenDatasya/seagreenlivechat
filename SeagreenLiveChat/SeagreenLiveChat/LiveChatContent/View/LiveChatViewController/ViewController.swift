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
        self.view.backgroundColor = .systemPurple
        self.view.addSubview(remoteView)
        self.view.addSubview(localView)
        cameraInput.setup(position: .front, locaPreview: localView)
        decorator.decorate(localView: localView, in: self.view)
        decorator.decorate(remoteView: remoteView, in: self.view)
    }



    func handleCameraState() {}


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
            .sink { state in
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


extension UIViewController {
   func add(_ child: UIViewController, frame: CGRect? = nil) {
       addChild(child)

       if let frame = frame {
           child.view.frame = frame
       }

       view.addSubview(child.view)
       child.didMove(toParent: self)
   }

   func remove() {
       willMove(toParent: nil)
       view.removeFromSuperview()
       removeFromParent()
   }
}
