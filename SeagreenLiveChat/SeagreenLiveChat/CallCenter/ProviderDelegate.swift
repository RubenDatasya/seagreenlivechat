//
//  ProviderDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 14/05/2023.
//

import Foundation
import AVFoundation
import CallKit

class ProviderDelegate: NSObject {
    private let callManager: CallManager
    private let provider: CXProvider
    private var calleeId: String = ""
    private var calllerId: String = ""

    init(callManager: CallManager) {
        self.callManager = callManager
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Seagreen")
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]

        return providerConfiguration
    }()

    func reportIncomingCall(
        callData : CallData,
        hasVideo: Bool = false,
        completion: ((Error?) -> Void)?
    ) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: callData.callerName)
        update.hasVideo = hasVideo
        callsActor(callData)
        onIncomingCall(callData)
        provider.reportNewIncomingCall(with: callData.callId, update: update) { error in
            if error == nil {
                let call = Call(uuid: callData.callId, handle: callData.callerName)
                self.callManager.add(call: call)
            }

            completion?(error)
        }
    }

    func callsActor(_ callData: CallData) {
        LiveChat.setLiveChatChannel(channel: callData.channel)
        LiveChat.shared.setCallActors(callerId: callData.callerid, remoteUserid: callData.calleeid)
    }

    private func onIncomingCall(_ callData: CallData) {
        Task(priority: .userInitiated) {
            let api = AnswerRequestApi()
            await api.answerCall(callData)
        }
    }

}

// MARK: - CXProviderDelegate
extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()

        for call in callManager.calls {
            call.end()
        }

        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

       // configureAudioSession()

        call.answer()

        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        stopAudio()

        call.end()

        action.fulfill()

        callManager.remove(call: call)
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        call.state = action.isOnHold ? .held : .active

        if call.state == .held {
            stopAudio()
        } else {
            startAudio()
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        let call = Call(uuid: action.callUUID, outgoing: true,
                        handle: action.handle.value)

       // configureAudioSession()

        call.connectedStateChanged = { [weak self, weak call] in
            guard
                let self = self,
                let call = call
            else {
                return
            }

            if call.connectedState == .pending {
                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
            }
        }

        call.start { [weak self, weak call] success in
            guard
                let self = self,
                let call = call
            else {
                return
            }

            if success {
                action.fulfill()
                self.callManager.add(call: call)
            } else {
                action.fail()
            }
        }
    }
}
