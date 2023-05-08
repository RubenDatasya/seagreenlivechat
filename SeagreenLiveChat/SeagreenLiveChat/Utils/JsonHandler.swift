//
//  JsonEncoder.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import Foundation

struct JsonHandler {

    static func encode<T: Encodable>(_ obj : T) -> String? {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(obj)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json
        }catch{
            Logger.severe("JsonEncoder encode, \(error)")
            return nil
        }
    }

    static func decode<T : Codable>(_ json: String) -> T? {
        let data =  json.data(using: .utf8)!
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        }catch {
            Logger.severe("JsonEncoder decode, \(error)")
            return nil
        }
    }
}
