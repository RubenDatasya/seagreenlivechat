//
//  ViewController.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

import Foundation
import Combine
import UIKit
import CallKit

@objc protocol GestureHandler {
    var resetGesture: UILongPressGestureRecognizer { get }
    var tapgesture:  UITapGestureRecognizer { get }
    func handleLongGesture(sender: UITapGestureRecognizer)
    func handleTapToFocus(sender: UITapGestureRecognizer)
}


class ViewController: UIViewController, GestureHandler {

    lazy var remoteView: UIView = UIView()
    var localView: CustomVideoSourcePreview = .init()
    lazy var decorator: ViewControllerDecorator = .init()
    var joinButton: UIButton!
    var subscriptions: Set<AnyCancellable> = .init()
    var viewModel: LiveChatViewModel

    lazy var resetGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture))
        gesture.minimumPressDuration = 0.5
        gesture.delegate = self
        return gesture
    }()

    lazy var tapgesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus))
        gesture.delegate = self
        return gesture
    }()


    init(viewModel: LiveChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        DispatchQueue.global(qos: .userInitiated).async { AgoraRtc.shared.destroy() }
    }

    private func initViews() {
        self.view.backgroundColor = UIColor(Colors.transparentGray)
        self.view.addSubview(remoteView)
        self.view.addSubview(localView)
        self.view.addGestureRecognizer(tapgesture)
        self.view.addGestureRecognizer(resetGesture)
        viewModel.cameraInput.setup(position: .front, locaPreview: localView)
        decorator.decorate(preview: localView, in: self.view)
        decorator.decorate(preview: remoteView, in: self.view, isFullScreen: true)
    }

    private func handleCameraState(state: CameraPosition) {
        decorator.decorate(preview: remoteView, in: self.view, isFullScreen: state == .front)
        decorator.decorate(preview: localView, in: self.view, isFullScreen: state == .rear)
    }

    private func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alert.addAction(.init(title: "Ok", style: .default, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
        })
    }

    private func joinChannels() {
        Task {
            await viewModel.joinChannel()
        }
    }

    private func handleHostingState( _ state: HostState) {
        switch state {
        case .received(let uid):
            AgoraRtc.shared.setupRemoteVideo(remoteView, uid: uid)
        case .disconnected:
            AgoraRtc.shared.setupRemoteVideo(.init(), uid: 0)
        }
    }

    @objc func handleLongGesture(sender: UITapGestureRecognizer) {
        viewModel.sendMessage(event: .resetFocus)
    }

    @objc func handleTapToFocus(sender: UITapGestureRecognizer) {
        let focusPoint = sender.location(in: self.view)
        let focusScaledPointX = focusPoint.x / view.frame.size.width
        let focusScaledPointY = focusPoint.y / view.frame.size.height
        let point = CGPoint(x: focusScaledPointX, y: focusScaledPointY)
        if let json = JsonHandler.encode(point) {
            viewModel.sendMessage(event: .focus(jsonPoint: json))
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

extension ViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UITapGestureRecognizer ||
            otherGestureRecognizer is UILongPressGestureRecognizer && gestureRecognizer is UITapGestureRecognizer
    }

}
