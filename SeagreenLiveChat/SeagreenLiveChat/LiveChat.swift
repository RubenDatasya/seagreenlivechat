//
//  LiveChat.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 10/05/2023.
//

import Foundation
import UIKit

public class LiveChat {
    public static func configure(
        appId: String = "0089641598304276ab3e6baf141c0258",
        certificateId: String = "12e9058b7aa64cd6898f2ab446f3e31f" ) {
        Constants.Secret.appid = appId
        Constants.Secret.certificate = certificateId
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
}
