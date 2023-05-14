//
//  User.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation
import FirebaseFirestoreSwift

struct User: FirebaseCodable {
    @DocumentID var id: String? = UUID().uuidString
    var name     : String
    var pushToken: String
}

struct PushToken: FirebaseCodable {
    @DocumentID var id: String? = UUID().uuidString
    var ownedby  : String
    var pushToken: String
    var deviceOS : String
}
