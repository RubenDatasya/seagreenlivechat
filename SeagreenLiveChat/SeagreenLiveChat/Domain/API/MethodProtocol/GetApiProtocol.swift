//
//  GetApiProtocol.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import FirebaseFunctions

protocol GetApiProtocol: AnyObject {
    associatedtype Value: Codable
    var endpoint: String { get }
}


extension GetApiProtocol where Value : FirebaseCodable {

    func fetch(openedBy: String) async throws -> Value {
        let fetcher = FirestoreData(.chatChannel)
        return try await fetcher.getEntry(id: openedBy, field: "openedBy")
    }

    func fetch(by channel: String) async throws -> Value {
        let fetcher = FirestoreData(.chatChannel)
        return try await fetcher.getEntry(id: channel, field: "name")
    }

    func fetchAll() async throws -> [Value] {
        let fetcher = FirestoreData(.chatChannel)
        return try await fetcher.getEntries()
    }
}

extension GetApiProtocol {
    func fetch(_ cloud : CloudFunction) async throws -> Value {
       try await withCheckedThrowingContinuation { continuation in
           Functions.functions().httpsCallable(cloud.function).call(cloud.params) { result, error in
               Logger.debug("\(cloud.function)")
             if let error = error as NSError? {
                 continuation.resume(throwing: FirebaseError.firebaseError(error))
                 return
             }
               if let dict = result?.data as? [String : Any], let data = dict["data"] {
                   Logger.debug("\(cloud.function) \(data)")
                   do {
                       let serialized = try JSONSerialization.data(withJSONObject: data)
                       let decoded = try JSONDecoder().decode(Value.self, from: serialized)
                       continuation.resume(with: .success(decoded))
                   }catch {
                       Logger.severe("\(error)")
                       continuation.resume(throwing: FirebaseError.decodeError(error.localizedDescription))
                   }
               }else{
                   Logger.severe("No data")
                   continuation.resume(throwing: FirebaseError.decodeError("no data"))

               }
           }
        }
    }

}
