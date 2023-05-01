//
//  LiveChatAlert.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation

enum LiveChatAlert {
    case error
    case permissionError
    case channelError
    case success

    var title: String {
        switch self {
        case .error,.permissionError, .channelError:
            return "Error"
        case .success:
            return "Success"
        }
    }

    var text: String {
        switch self {
        case .permissionError:
            return "Permissions were not granted"
        case .error:
            return "Something wrong happened"
        case .success:
           return "Successfully joined the channel"
        case .channelError:
            return "Could not join channel"
        }
    }
}
