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
    let baseURL = "https://c24f-2a10-8007-2729-0-2c5b-3267-9b8d-4894.ngrok-free.app"
    let appId: String  = "0089641598304276ab3e6baf141c0258"

    //To update per session
    var token: String  = "007eJxTYJixS8bv06aFvVs/ceS4ss35zqrx553QkVObC7sbp0xtybJVYDAwsLA0MzE0tbQwNjAxMjdLTDJONUtKTDM0MUw2MDK1EJzln9IQyMjw+SsvMyMDBIL4AgzFqYnpRampeTmZZanJGYklDAwAF7ckdQ=="

    var channel: String = "seagreenlivechat"
}
