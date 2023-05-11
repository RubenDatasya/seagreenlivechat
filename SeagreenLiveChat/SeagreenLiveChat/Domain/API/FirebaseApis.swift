//
//  UserApi.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

protocol FirebaseCodable: Codable, Identifiable {
    var id : String? { get set}
}

class UserApi: FirebaseApiProtocol {
    var datatype: FirestoreData.FirestoreDataType = .user
}

extension UserApi:  GetApiProtocol {
    var endpoint: String { .firebase }
    typealias Value = User
}

extension UserApi: CreateProtocol {
    typealias CreateValue = User
}

class PushTokenApi : FirebaseApiProtocol {
    var datatype: FirestoreData.FirestoreDataType = .pushtokens
}

extension PushTokenApi: GetApiProtocol {
    var endpoint: String { .firebase }
    typealias Value = PushToken
}

extension PushTokenApi: CreateProtocol {
    typealias CreateValue = PushToken
}

