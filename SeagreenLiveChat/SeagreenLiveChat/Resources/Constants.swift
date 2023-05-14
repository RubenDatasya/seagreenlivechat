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
        static var appid: String = ""
    }

    struct Credentials {
        static var bundleId     : String = ""
        static var appName      : String = ""
        static var currentUser  : String =  ""
        static var uid          : UInt =  UInt(abs(currentUser.hashValue))
        static var channel      : String = ""
        static var remoteUser   : UInt = 0
    }
}
