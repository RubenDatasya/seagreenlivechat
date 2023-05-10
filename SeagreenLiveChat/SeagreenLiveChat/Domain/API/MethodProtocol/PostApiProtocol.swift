//
//  PostApiProtocol.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

protocol PostApiProtocol: AnyObject {
    associatedtype PostValue: Codable
    var endpointPost: String { get }
}


extension PostApiProtocol where PostValue : FirebaseCodable {
    @discardableResult
    func post(model: PostValue) async throws -> PostValue {
        let fetcher = FirestoreData(.chatChannel)
        return try await fetcher.createEntry(model: model)
    }
}

extension PostApiProtocol {

}
