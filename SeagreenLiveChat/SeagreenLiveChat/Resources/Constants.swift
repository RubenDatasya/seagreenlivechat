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
        static let channel: String = "seagreenlivechat_4"
        static let token: String  = "007eJxTYLh8PkDINLeXb9uNJwaqsQ7CaWfE6sLyb/7aIn+9nU8g/ZcCg4GBhaWZiaGppYWxgYmRuVliknGqWVJimqGJYbKBkanFa8fwlIZARoYpn1sYGKEQxBdiKE5NTC9KTc3LySxLTc5ILIk3YWAAALYEI6o="
    }

    struct API {
        static let baseURL: String = "https://706d-94-154-123-67.ngrok-free.app"
    }

}
