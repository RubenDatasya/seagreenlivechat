//
//  ChatChannelApi.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation


class ChatChannelApi: GetApiProtocol {
    typealias Value = ChatChannel
    var endpoint: String = .firebase
}


extension ChatChannelApi: PostApiProtocol {
    typealias PostValue = ChatChannel
    var endpointPost: String {
        .firebase
    }
}


extension ChatChannelApi: UpdateApiProtocol {
    typealias UpdateValue = ChatChannel
    var endpointUpdate: String {
        .firebase
    }
}
