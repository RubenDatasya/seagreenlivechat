//
//  Constants.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import UIKit

enum Constants {

    struct Secret {
        static let appid: String = "0089641598304276ab3e6baf141c0258"
        static let certificate: String = "12e9058b7aa64cd6898f2ab446f3e31f"
    }

    struct Credentials {
        static let currentUser =  UIDevice.current.identifierForVendor?.uuidString ?? ""
        static let rtmUser =  UUID().uuidString
        static let channel: String = "seagreenlivechat_3"
        static let token: String  = "007eJxTYJBqu3gisa9sxS7plT8L9ldNuhIt7nH55uLfeefnHj1x6k+xAoOBgYWlmYmhqaWFsYGJkblZYpJxqllSYpqhiWGygZGpxTS9oJSGQEaGhLm8jIwMEAjiCzEUpyamF6Wm5uVklqUmZySWxBszMAAALlsm5g=="
    }

    struct API {
        static let baseURL: String = "https://f0de-94-154-123-67.ngrok-free.app"

    }

}
