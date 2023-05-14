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
    func answerCall(_ callData: CallData, callState: CallStatus = .accepted) async -> Bool {
        do {
            let result = try await command(.callAccepted(answerCallData: .init(
                bundleId: callData.bundleId,
                channel : callData.channel,
                callId  : callData.callId,
                callerid: callData.callerid,
                calleeid: callData.calleeid))
            )
            return result
        } catch {
            print("answerCall", error)
            return false
        }
    }
}

class EndCallRequestApi: CommandRequestProtocol {
    @discardableResult
    func endCall(_ callData: EndCallData) async -> Bool {
        do {
            let result = try await command(.endCallRequest(endCallData: callData))
            return result
        } catch {
            print("answerCall", error)
            return false
        }
    }
}



