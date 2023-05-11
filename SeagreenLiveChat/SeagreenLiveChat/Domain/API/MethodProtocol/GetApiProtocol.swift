//
//  GetApiProtocol.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import FirebaseFunctions

protocol FirebaseApiProtocol {
    var datatype: FirestoreData.FirestoreDataType { get set }
}

protocol GetApiProtocol: AnyObject {
    associatedtype Value: Codable
    var endpoint: String { get }
}

protocol CreateProtocol: AnyObject {
    associatedtype CreateValue: Codable
}

extension CreateProtocol where Self : FirebaseApiProtocol, CreateValue: FirebaseCodable {

    func create(_ obj: CreateValue) async throws -> CreateValue {
        let firebaseData = FirestoreData(datatype)
        return try await firebaseData.create(id: obj.id!, model: obj)
    }
}

extension GetApiProtocol where Self: FirebaseApiProtocol, Value: FirebaseCodable {

    func fetch(with id: String) async throws -> Value {
        let firebaseData =  FirestoreData(datatype)
        return try await firebaseData.getEntry(id: id)
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
                       continuation.resume(throwing: FirebaseError.decodeError(error.localizedDescription))
                   }
               }else{
                   continuation.resume(throwing: FirebaseError.nodatareturned)
               }
           }
        }
    }
}

protocol CommandRequestProtocol {}

extension CommandRequestProtocol {

    func command(_ cloud: CloudFunction) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            Functions.functions().httpsCallable(cloud.function).call(cloud.params) { result, error in
                Logger.debug("\(cloud.function)")
                if let error = error as NSError? {
                    continuation.resume(throwing: FirebaseError.firebaseError(error))
                    return
                }
                continuation.resume(with: .success(true))
            }
        }
    }
}
