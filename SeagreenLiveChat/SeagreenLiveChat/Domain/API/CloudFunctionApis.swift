//
//  LiveChatToken.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

class AgoraTokenApi: GetApiProtocol {
    typealias Value = Token
    let endpoint: String = .firebase
}


class CallRequestApi: CommandRequestProtocol {

    func executeCall() async  -> Bool {
        do {
          let result = try await command(.callRequest(channelName: "seagreenlivechat_4", caller: Constants.Credentials.currentUser, callee: "BZclfZhVrnMbfsvGCBsmRnEZ2bj1"))
            return result
        }catch {
            print("call", error)
            return false
        }

    }

}
