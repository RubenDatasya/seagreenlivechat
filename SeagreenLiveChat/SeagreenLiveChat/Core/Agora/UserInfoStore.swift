//
//  UserInfoStore.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation
import AgoraChat

class UserInfoStore: NSObject {
    static let shared = UserInfoStore()

    private let queue = DispatchQueue(label: "UserInfoStore", attributes: .concurrent)

    private var userInfoMap: [String: AgoraChatUserInfo] = [:]

    func getUserInfo(userId: String) -> AgoraChatUserInfo? {
        var info: AgoraChatUserInfo?
        self.queue.sync {
            info = self.userInfoMap[userId]
        }
        return info
    }

    func setUserInfo(_ userInfo: AgoraChatUserInfo, userId: String) {
        self.queue.async(flags: .barrier) {
            self.userInfoMap[userId] = userInfo
        }
    }

    func fetchUserInfosFromServer(userIds: [String], refresh: Bool = false, completion: (() -> Void)? = nil) {
        AgoraChatClient.shared().userInfoManager?.fetchUserInfo(byId: userIds, completion: { dict, error in
            if let dict = dict as? [String: AgoraChatUserInfo] {
                self.queue.sync(flags: .barrier) {
                    for item in dict {
                        self.userInfoMap[item.key] = item.value
                    }
                }
                DispatchQueue.main.async {
                    completion?()
                }
            } else {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        })
    }
}
