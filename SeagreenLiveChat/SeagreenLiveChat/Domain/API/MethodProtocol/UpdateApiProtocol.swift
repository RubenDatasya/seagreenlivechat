//
//  UpdateApiProtocol.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

protocol UpdateApiProtocol: AnyObject {
    associatedtype UpdateValue: Codable
    var endpointUpdate: String { get }
}


extension UpdateApiProtocol where UpdateValue : FirebaseCodable {
    @discardableResult
    func update(_ id: String, model: UpdateValue) async throws -> UpdateValue {
        let fetcher = FirestoreData(.chatChannel)
        return try await fetcher.updateEntry(id: id, model: model)
    }
}

extension PostApiProtocol {

}
