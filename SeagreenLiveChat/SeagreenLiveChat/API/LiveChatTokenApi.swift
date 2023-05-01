//
//  LiveChatToken.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

class LiveChatTokenAPI: GetApiProtocol {
    typealias Value = LiveChatToken
    let endpoint: String = "/chatToken"
}
