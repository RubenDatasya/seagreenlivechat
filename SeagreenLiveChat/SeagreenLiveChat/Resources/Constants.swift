//
//  Constants.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import UIKit

class Constants {

    private init(){}

    static let shared =  Constants()

    let currentUser =  UIDevice.current.identifierForVendor?.uuidString ?? ""
    let rtmUser =  UUID().uuidString
    let baseURL = "https://bb09-94-154-123-67.ngrok-free.app"
    let appId: String  = "0089641598304276ab3e6baf141c0258"

    //To update per session
    var token: String  = "007eJxTYHh/ZuHMrdZfjho6Ptxy6K+a0e2jcXOmXJh4Na7h9bT5vdduKzAYGFhYmpkYmlpaGBuYGJmbJSYZp5olJaYZmhgmGxiZWvw/EZDSEMjIsEpnFgMjFIL4QgzFqYnpRampeTmZZanJGYkl8YYMDADXGyk2"

    var channel: String = "seagreenlivechat_1"
}
