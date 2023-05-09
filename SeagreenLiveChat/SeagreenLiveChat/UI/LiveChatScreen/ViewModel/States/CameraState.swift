//
//  CameraState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation

struct CameraState: CameraPositionProtocol {
    var position: CameraPosition
    var isSharing: Bool = false
}

