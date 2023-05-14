//
//  LiveChatToken.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

class AgoraTokenApi: GetApiProtocol {
    typealias Value = Token
    let endpoint: String = .firebase
}


class CallRequestApi: CommandRequestProtocol {

    @discardableResult
    func executeCall(startCallData: StartCallData) async  -> Bool {
        do {
            let result = try await command(.callRequest(callData: startCallData))
            return result
        }catch {
            print("call", error)
            return false
        }
    }
}

class AnswerRequestApi: CommandRequestProtocol {
    @discardableResult
    func answerCall(_ callData: CallData, callState: CallState = .answered) async -> Bool {
        do {
            let result = try await command(.callAnswered(answerCallData: .init(
                bundleId: callData.bundleId,
                channel : callData.channel,
                callerid: callData.callerid)))
            return result
        } catch {
            print("answerCall", error)
            return false
        }
    }
}
