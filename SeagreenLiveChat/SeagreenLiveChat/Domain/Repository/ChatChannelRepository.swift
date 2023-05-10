//
//  ChatChannelRepository.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation


protocol ChatChannelRepositoryProtocol {
    associatedtype API = (any GetApiProtocol & PostApiProtocol & UpdateApiProtocol)
    var api:  API { get }
    func getAll() async throws -> [ChatChannel]
    func getChat(openedBy: String) async throws -> ChatChannel
    func getChat(by channel: String) async throws -> ChatChannel
    func createChat(with chat: ChatChannel) async throws -> ChatChannel
    func updateChat(at chatId: String, and model: ChatChannel) async throws  -> ChatChannel
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
