//
//  CameraActionButton.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI

enum CameraActionType : String {
    case zoom = "plus.magnifyingglass"
    case zoomout = "minus.magnifyingglass"
    case brightness = "wand.and.rays"
    case brightnessDown = "wand.and.rays.inverse"
    case move = "cross.circle"
    case cameraReverse = "arrow.triangle.2.circlepath.camera"
    case shut = "iphone.gen2.slash"
    case flash = "lightbulb"
    case flashDown = "lightbulb.led"
}


struct CameraActionButton: View {

    var color   : Color = Color.white.opacity(0.6)
    let image   : CameraActionType
    let action  : ()->Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: image.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
        .padding()
        .foregroundColor(color)
        .background(Color.purple)
        .clipShape(Circle())
    }
}

struct CameraActionButton_Previews: PreviewProvider {
    static var previews: some View {
        CameraActionButton(image: .brightness, action: { })
    }
}
