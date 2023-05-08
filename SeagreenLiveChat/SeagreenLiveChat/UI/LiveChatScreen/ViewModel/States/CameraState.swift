//
//  CameraState.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation

struct CameraState: CameraPositionProtocol {
    var position: CameraPosition
    var zoom: CGFloat = 0.0
    var isFlashOn: Bool = false
    var brightness: Float = 0.5
}

