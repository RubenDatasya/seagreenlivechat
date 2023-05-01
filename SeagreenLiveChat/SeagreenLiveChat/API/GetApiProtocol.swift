//
//  GetApiProtocol.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

protocol GetApiProtocol {
    associatedtype Value: Codable
    var endpoint: String { get }
}

struct LiveChatToken: Codable{
    let value: String
}

struct MessagingToken : Codable{
    let value: String
}

extension GetApiProtocol {

    func fetch(userid : String) async -> Value {
        var url = URL(string: Constants.shared.baseURL.appending(endpoint))!
        url.append(queryItems: [
            URLQueryItem(name: "userid", value: userid)
        ])
        var request = URLRequest(url: url)
        request.setValue("pouf", forHTTPHeaderField: "ngrok-skip-browser-warning")
        let (data, _) = try! await URLSession.shared.data(for: request)
        return try! JSONDecoder().decode(Value.self, from: data)
    }

}
