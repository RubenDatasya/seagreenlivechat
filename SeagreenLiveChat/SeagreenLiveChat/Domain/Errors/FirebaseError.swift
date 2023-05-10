//
//  FirebaseError.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

enum FirebaseError: LocalizedError {
    case nodatareturned
    case decodeError(String)
    case firebaseError(Error)
}
