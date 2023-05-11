//
//  LiveChat.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 10/05/2023.
//

import Foundation
import UIKit
import AgoraRtmKit

public class LiveChat: NSObject {

    private var inviter: AgoraRtmCallKit? {
        return AgoraRtm.shared.callKit
    }

    private var prepareToVideoChat: (() -> Void)?
    private var navigateToLiveChat: (() -> Void)?
    private var calleeId: String? = nil
    private static var isDemoMode: Bool =  false
    lazy var appleCallKit : CallCenter = .init(delegate: self)

    static let shared : LiveChat = .init()

    private override init() {
        super.init()
    }



    public static func configure(
        appId: String = "0089641598304276ab3e6baf141c0258",
        appname: String = "Seagrean"
    ) {
        Constants.Secret.appid = appId
        Constants.Credentials.appName = appname
    }

    public static func setMode(isDemoMode: Bool){
        self.isDemoMode =  isDemoMode
    }

    public static func setCurrentUser(
        userId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
    ) {
        //Constants.Credentials.currentUser = "Ruben"
    }

    public static func setLiveChatChannel(
        channel: String = "seagreenlivechat_4"
    ) {
        Constants.Credentials.channel =  channel
    }

    public func isDemo() -> Bool { LiveChat.isDemoMode  }

    // the remoteUserid is the one sent to login with AgoraRtm
    public func setCalleeId(remoteUserid: String) {
        calleeId =  remoteUserid
    }

    // the user id is the one sent to login with AgoraRtm
    public func startOutgoingCall(to userid : String) {
        calleeId =  userid
        appleCallKit.startOutgoingCall(of: userid)
    }

    public func showIncomingCall(of userid : String, withData: [AnyHashable : Any]) {
        appleCallKit.showIncomingCall(of: userid)
    }

    public func onCallAccepted(navigate : @escaping () -> Void){

    }
}

extension LiveChat : CallCenterDelegate {

    func callCenter(_ callCenter: CallCenter, answerCall session: String) {
        guard let inviter = inviter else {
            fatalError("rtm inviter nil")
        }
        guard let channel = inviter.lastIncomingInvitation?.content else {
            fatalError("lastIncomingInvitation content nil")
        }
        guard let remote = UInt(session) else {
            fatalError("string to int fail \(session)")
        }

        inviter.acceptLastIncomingInvitation()

        self.prepareToVideoChat = { [weak self] in
            Constants.Credentials.channel = channel
            Constants.Credentials.remoteUser = remote
            //Show VideoChat view
            self?.navigateToLiveChat?()
        }
    }

    func callCenter(_ callCenter: CallCenter, declineCall session: String) {
        print("callCenter declineCall")
        guard let inviter = inviter else {
            fatalError("rtm inviter nil")
        }
        appleCallKit.endCall(of: session)
        inviter.refuseLastIncomingInvitation {  [weak self] (error) in
            //back to chat view
            // error ui
        }
    }

    func callCenter(_ callCenter: CallCenter, startCall session: String) {
        print("callCenter startCall")
        let kit = AgoraRtm.shared.rtm

        guard let localNumber = calleeId else {
            fatalError("no one to call")
        }

        guard let inviter = AgoraRtm.shared.callKit else {
            fatalError("callkit is nil")
        }

        let remoteNumber = session

        // rtm query online status
        kit.queryPeerOnline(remoteNumber, success: { onlineStatus in
            switch onlineStatus {
            case .online:      sendInvitation(remote: remoteNumber)
            case .offline:     break // back to chat view
            case .unreachable: break // back to chat view
            @unknown default:  fatalError("queryPeerOnline")
            }
        }) { error in
            // back to chat view
            //display error
        }

        // rtm send invitation
        func sendInvitation(remote: String) {
            let channel = "\(localNumber)-\(remoteNumber)-\(Date().timeIntervalSinceReferenceDate)"

            inviter.sendInvitation(peer: remote, channel: channel) { [weak self] in
                self?.appleCallKit.setCallConnected(of: remote)
                guard let remote = UInt(remoteNumber) else {
                    fatalError("string to int fail")
                }

                var data: (channel: String, remote: UInt)
                data.channel = channel
                data.remote = remote

            } refused: {
                //back to chat view
                // refused ui
            } fail: { error in
                //back to chat view
                // error ui
            }

        }
    }

    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String) {
        print("callCenter muteCall")
    }

    func callCenter(_ callCenter: CallCenter, endCall session: String) {
        print("callCenter endCall")
        appleCallKit.endCall(of: session)
        self.prepareToVideoChat = nil
    }

    func callCenterDidActiveAudioSession(_ callCenter: CallCenter) {
        print("callCenter didActiveAudioSession")
        // Incoming call
        if let prepare = self.prepareToVideoChat {
            prepare()
        }
    }
}

