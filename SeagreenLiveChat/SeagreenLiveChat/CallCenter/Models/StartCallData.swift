//
//  StartCallData.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

struct StartCallData: Identifiable {
    var id: UUID = .init()
    var bundleId: String
    var name: String
    var calleeid: String
    var callername: String
    var callerid: String
    var channel: String
}
