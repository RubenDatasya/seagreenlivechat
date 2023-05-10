//
//  AgoraTokenRepository.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 10/05/2023.
//

import Foundation

protocol AgoraTokenRepositoryProtocol {
    associatedtype API where API: GetApiProtocol, API.Value : CloudCodable
    var api : API { get }
    func getRtcToken(with channel : String, uid: UInt) async throws -> Token
    func getRtmToken(with userid : String ) async throws -> Token
}

class AgoraTokenRepository: AgoraTokenRepositoryProtocol {

    typealias API = AgoraTokenApi

    let api: AgoraTokenApi

    init(api: API = AgoraTokenApi()) {
        self.api = api
    }

    func getRtmToken(with userid: String) async throws -> Token {
        try await api.fetch(.getRtmToken(userid: userid))
    }

    func getRtcToken(with channel: String, uid: UInt) async throws -> Token {
        try await api.fetch(.getRtcToken(channelName: channel, uid: uid))
    }

}
