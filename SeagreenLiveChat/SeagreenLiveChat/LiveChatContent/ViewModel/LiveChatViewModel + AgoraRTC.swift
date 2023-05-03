//
//  LiveChatViewModel + AgoraVideoFrameDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation
import AgoraRtcKit


extension LiveChatViewModel: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        hostEvent.send(.received(uid: uid))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        hostEvent.send(.disconnected(uid: uid))
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError AgoraErrorCode", errorCode.rawValue)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        print("didOccur AgoraEncryptionErrorType", errorType.rawValue)
    }
}
