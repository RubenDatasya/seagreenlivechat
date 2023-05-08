//
//  CameraPosition.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation

protocol CameraPositionProtocol {
    var position: CameraPosition { get set}
}

extension CameraPositionProtocol {

    internal var current: CameraPosition {
        get { position }
        set { position = newValue }
    }

    mutating func inverse() {
        if current == .front {
            current = .rear
        } else {
            current = .front
        }
    }
}

enum CameraPosition {
    case rear
    case front
}
