//
//  CallProvider.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation
import CallKit

class CallProvider: NSObject,  CXProviderDelegate {

    var provider: CXProvider
    let callController: CXCallController
    private let callCommand = CallRequestApi()

    override init() {
        let config = CallKit.CXProviderConfiguration()
        config.includesCallsInRecents = true
        config.supportsVideo = true
        self.provider = CXProvider(configuration: config)
        self.callController =  CXCallController()
        super.init()
        self.provider.setDelegate(self, queue: DispatchQueue.main)
    }

    func providerDidReset(_ provider: CXProvider) {
    }


    func startCall(startCallData: StartCallData) async throws {
        guard await callCommand.executeCall(startCallData: startCallData) else {
            throw FirebaseError.couldNotSendPush
        }
        
        let callId = UUID()
        let recipient = CXHandle(type: .generic, value: startCallData.name)
        let startAction = CXStartCallAction(call: callId, handle: recipient)
        let transaction = CXTransaction(action: startAction)

        try await callController.request(transaction)
    }

    func handleIncomingCall(from : String) {
        let update =  CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: from)
        update.hasVideo = true
        provider.reportNewIncomingCall(with: .init(), update: update) { error in
            if let error = error {
                print("handleIncomingcall", error.localizedDescription)
            }
        }

    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer action")
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("cancel action")
        action.fail()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start call action")
        action.fulfill()
    }
}

