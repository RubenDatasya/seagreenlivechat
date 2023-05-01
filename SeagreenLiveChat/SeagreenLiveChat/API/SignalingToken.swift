//
//  SignalingToken.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

class SignalingTokenAPI: GetApiProtocol {
    typealias Value = MessagingToken
    let endpoint: String = "/messagingToken"
}
