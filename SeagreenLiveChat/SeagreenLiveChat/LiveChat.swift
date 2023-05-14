//
//  LiveChat.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 10/05/2023.
//

import Foundation
import UIKit
import AgoraRtmKit
import FirebaseAuth

public class LiveChat: NSObject {

    private var calleeId: String? = nil
    private var callerId: String? = nil
    private static var isDemoMode: Bool =  false
    //  lazy var appleCallKit : CallProvider = .init()

    static let shared : LiveChat = .init()

    private override init() {
        super.init()
    }

    public static func configure(
        appId       : String = "0089641598304276ab3e6baf141c0258",
        appname     : String = "Seagrean",
        bundleId    : String
    ) {
        Constants.Secret.appid = appId
        Constants.Credentials.appName = appname
        Constants.Credentials.bundleId = bundleId
    }

    public static func setMode(isDemoMode: Bool){
        self.isDemoMode =  isDemoMode
    }

    public static func setCurrentUser(
        userId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
    ) {
        Constants.Credentials.currentUser = userId
    }

    public static func setLiveChatChannel(
        channel: String = "seagreenlivechat_4"
    ) {
        Constants.Credentials.channel =  channel
    }

    public func isDemo() -> Bool { LiveChat.isDemoMode  }

    // the remoteUserid is the one sent to login with AgoraRtm
    public func setCallActors(callerId: String,remoteUserid: String) {
        self.callerId = callerId
        self.calleeId = remoteUserid
    }

    public func getActors() -> (String, String) {
        (callerId ?? "" , calleeId ?? "" )
    }

//    // the user id is the one sent to login with AgoraRtm
//    public func startOutgoingCall(to userid : String) {
//        calleeId =  userid
//        appleCallKit.startCall(startCallData: <#T##StartCallData#>)
//        appleCallKit.startOutgoingCall(of: userid)
//    }

    public func showIncomingCall(with data : [AnyHashable : Any]) {
       // appleCallKit.handleIncomingCall(callData: CallData.toCallData(data))
    }

    public func onCallAccepted(with data : [AnyHashable : Any]){
//        Auth.auth().signInAnonymously {[weak self] _,_  in
//            self?.appleCallKit.endCall(callData: EndCallData.toEndCallData(data))
//        }
    }
}
