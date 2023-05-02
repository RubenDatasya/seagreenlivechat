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
    let baseURL = "https://f0de-94-154-123-67.ngrok-free.app"
    let appId: String  = "0089641598304276ab3e6baf141c0258"

    //To update per session
    var token: String  = "007eJxTYDi784fslxvV96LXh5+6dNd43ixZSfHly6PlbSXZH2466zxbgcHAwMLSzMTQ1NLC2MDEyNwsMck41SwpMc3QxDDZwMjUoulmQEpDICOD+YpFrIwMEAjiCzEUpyamF6Wm5uVklqUmZySWxBsxMAAAhhglOg=="
    
    var channel: String = "seagreenlivechat_2"
}
