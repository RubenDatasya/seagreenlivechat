//
//  UserDefaults + Extensions.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation

extension UserDefaults {

    static func saveFuid(_ uid: String) {
        UserDefaults.standard.setValue(uid, forKey: "fuid")
    }

    static func getFuid() -> String {
        guard let fuid = UserDefaults.standard.value(forKey: "fuid") as? String else {
            fatalError("User not registered")
        }
        return fuid
    }
}
