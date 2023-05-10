//
//  ChatChannelRepository.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation


protocol ChatChannelRepositoryProtocol {
    associatedtype API where API : GetApiProtocol & PostApiProtocol & UpdateApiProtocol,
                             API.PostValue : FirebaseCodable,
                             API.Value : FirebaseCodable,
                             API.UpdateValue : FirebaseCodable
    var api:  API { get }
    func getAll() async throws -> [API.Value]
    func getChat(openedBy: String) async throws -> API.Value
    func getChat(by channel: String) async throws -> API.Value
    func createChat(with chat: ChatChannel) async throws -> API.PostValue
    func updateChat(at chatId: String, and model: ChatChannel) async throws  -> API.UpdateValue
}

class ChatChannelRepository: ChatChannelRepositoryProtocol {

    typealias API = ChatChannelApi

    let api: ChatChannelApi

    init(api: API = ChatChannelApi()) {
        self.api = api
    }

    func getAll() async throws -> [ChatChannel] {
        return try await api.fetchAll()
    }

    @discardableResult
    func getChat(openedBy: String) async throws -> ChatChannel {
        try await api.fetch(openedBy: openedBy)
    }

    @discardableResult
    func getChat(by channel: String) async throws -> ChatChannel {
        try await api.fetch(by: channel)
    }

    @discardableResult
    func createChat(with chat: ChatChannel) async throws -> ChatChannel {
        return try await api.post(model: chat)
    }


    @discardableResult
    func updateChat(at chatId: String, and model: ChatChannel) async throws -> ChatChannel {
        return try await api.update(chatId, model: model)
    }

}
