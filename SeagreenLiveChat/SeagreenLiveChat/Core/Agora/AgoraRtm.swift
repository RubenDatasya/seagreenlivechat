//
//  AgoraRtm.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 04/05/2023.
//

import Foundation
import AgoraRtmKit

enum RtmError : LocalizedError {
    case failure(String)
    case severeFailure(Error)

}

typealias Completion = (() -> Void)?
typealias ErrorCompletion = ((RtmError) -> Void)?

enum LoginStatus {
    case online, offline
}

protocol AgoraRtmInviterDelegate: NSObjectProtocol {
    func inviter(_ inviter: AgoraRtmCallKit, didReceivedIncoming invitation: AgoraRtmInvitation)
    func inviter(_ inviter: AgoraRtmCallKit, remoteDidCancelIncoming invitation: AgoraRtmInvitation)
}

struct AgoraRtmInvitation {
    var content: String?
    var caller: String // outgoint call
    var callee: String // incoming call

    fileprivate static func agRemoteInvitation(_ ag: AgoraRtmRemoteInvitation) -> AgoraRtmInvitation {
        let account = Constants.Credentials.currentUser
        let invitation = AgoraRtmInvitation(content: ag.content,
                                            caller: ag.callerId,
                                            callee: account)

        return invitation
    }

    fileprivate static func agLocalInvitation(_ ag: AgoraRtmLocalInvitation) -> AgoraRtmInvitation {
        let account = Constants.Credentials.currentUser
        let invitation = AgoraRtmInvitation(content: ag.content,
                                            caller: account,
                                            callee: ag.calleeId)
        return invitation
    }
}

class AgoraRtm: NSObject {

    static let shared = AgoraRtm()

    private var agoraRtm: AgoraRtmKit!

    fileprivate var lastOutgoingInvitation: AgoraRtmLocalInvitation?
    fileprivate var lastIncomingInvitation: AgoraRtmRemoteInvitation?
    fileprivate var callKitRefusedBlock: Completion = nil
    fileprivate var callKitAcceptedBlock: Completion = nil

    weak var inviterDelegate: AgoraRtmInviterDelegate?

    var rtm : AgoraRtmKit {
        return agoraRtm
    }

    lazy var tokenRepository = AgoraTokenRepository()
    private var rtmChannel: AgoraRtmChannel?


    private override init() {
        super.init()
    }

    func initalize() {
        agoraRtm = .init(appId: Constants.Secret.appid, delegate: nil)
    }

    func setDelegate(_ delegate: AgoraRtmDelegate & AgoraRtmInviterDelegate){
        agoraRtm.agoraRtmDelegate = delegate
        inviterDelegate = delegate
    }

    @discardableResult
    func joinMessageChannel(delegate: AgoraRtmChannelDelegate) async throws -> Bool  {
        let token = try await tokenRepository.getRtmToken(with: Constants.Credentials.currentUser)
        let login = await agoraRtm.login(byToken: token.value, user: Constants.Credentials.currentUser)
        if login == .ok {
            try createMessageChannel(delegate: delegate)
            await rtmChannel?.join()
            Logger.info("joinMessageChannel, success")
            return true
        } else {
            Logger.info("joinMessageChannel  AgoraRtmLoginErrorCode failure \(login)")
            return false
        }
    }

    func sendMessage(event: ChannelMessageEvent) {
        self.rtmChannel?.send(AgoraRtmMessage(text: event.title )){ error in
            Logger.error("sendMessage \(error)")
        }
    }

    func leaveChannel() {
         rtmChannel?.leave { (error) in
             Logger.error("leaveChannel \(error)")
         }
        rtmChannel = nil
     }

    func startCall(calleeId: String, channelId: String) {
        let localInvitation = AgoraRtmLocalInvitation()
        localInvitation.calleeId = calleeId
        localInvitation.channelId = channelId
        agoraRtm.rtmCallKit?.send(localInvitation){ result in
            Logger.debug("AgoraRtmInvitationApiCallErrorCode, \(result)")
        }
    }


    private func createMessageChannel(delegate: AgoraRtmChannelDelegate) throws {
        guard let rtmChannel = agoraRtm.createChannel(withId: Constants.Credentials.channel, delegate: delegate) else {
            throw LiveChatAlert.channelError
        }
        self.rtmChannel = rtmChannel
    }
}


extension AgoraRtmCallKit {
    enum Status {
        case outgoing, incoming, none
    }

    var lastIncomingInvitation: AgoraRtmInvitation? {
        if let agInvitation =  AgoraRtm.shared.lastIncomingInvitation {
            let invitation = AgoraRtmInvitation.agRemoteInvitation(agInvitation)
            return invitation
        } else {
            return nil
        }
    }

    var status: Status {
        if let _ = AgoraRtm.shared.lastOutgoingInvitation {
            return .outgoing
        } else if let _ = AgoraRtm.shared.lastIncomingInvitation {
            return .incoming
        } else {
            return .none
        }
    }

    func sendInvitation(peer: String, channel: String, accepted: Completion = nil, refused: Completion = nil, fail: ErrorCompletion = nil) {
        print("rtm sendInvitation peer: \(peer)")

        let rtm = AgoraRtm.shared
        let invitation = AgoraRtmLocalInvitation(calleeId: peer)
        invitation.content = channel
        rtm.lastOutgoingInvitation = invitation

        send(invitation) { [unowned rtm] (errorCode) in
            guard errorCode == AgoraRtmInvitationApiCallErrorCode.ok else {
                if let fail = fail {
                    fail(RtmError.failure("rtm send invitation fail: \(errorCode.rawValue)"))
                }
                return
            }

            rtm.callKitAcceptedBlock = accepted
            rtm.callKitRefusedBlock = refused
        }
    }

    func cancelLastOutgoingInvitation(fail: ErrorCompletion = nil) {
        let rtm = AgoraRtm.shared

        guard let last = rtm.lastOutgoingInvitation else {
            return
        }

        cancel(last) { (errorCode) in
            guard errorCode == AgoraRtmInvitationApiCallErrorCode.ok else {
                if let fail = fail {
                    fail(.failure("rtm cancel invitation fail: \(errorCode.rawValue)"))
                }
                return
            }
        }

        rtm.lastOutgoingInvitation = nil
    }

    func refuseLastIncomingInvitation(fail: ErrorCompletion = nil) {
        let rtm = AgoraRtm.shared

        guard let last = rtm.lastIncomingInvitation else {
            return
        }

        refuse(last) { (errorCode) in
            guard errorCode == AgoraRtmInvitationApiCallErrorCode.ok else {
                if let fail = fail {
                    fail(.failure("rtm refuse invitation fail: \(errorCode.rawValue)"))
                }
                return
            }
        }
    }

    func acceptLastIncomingInvitation(fail: ErrorCompletion = nil) {
        let rtm = AgoraRtm.shared

        guard let last = rtm.lastIncomingInvitation else {
            fatalError("rtm lastIncomingInvitation")
        }

        accept(last) {(errorCode) in
            guard errorCode == AgoraRtmInvitationApiCallErrorCode.ok else {
                if let fail = fail {
                    fail(.failure("rtm refuse invitation fail: \(errorCode.rawValue)"))
                }
                return
            }
        }
    }
}
