//
//  CallNotificationObserver.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation
import Combine

class CallNotificationObserver {

    var subscriptions: Set<AnyCancellable> = .init()

    init(onAnswered: @escaping (CallData) -> Void) {
        NotificationCenter.default.publisher(for: CallNotification.name)
            .compactMap { $0.object as? CallNotification }
            .map(\.state)
            .sink { state in
                switch state {
                case .answered(let calldata):
                    onAnswered(calldata)
                case .ended:
                    break
                case .started:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    deinit {
        subscriptions.removeAll()
    }

}
