//
//  ContentView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

//cetirficate = 12e9058b7aa64cd6898f2ab446f3e31f
// app id = 0089641598304276ab3e6baf141c0258

import SwiftUI

enum CameraActionType : String {
    case zoom = "plus.magnifyingglass"
    case zoomout = "minus.magnifyingglass"
    case brightness = "wand.and.rays"
    case move = "cross.circle"
    case cameraReverse = "arrow.triangle.2.circlepath.camera"
    case shut = "iphone.gen2.slash"
    case flash = "lightbulb"
}

struct ContentView: View {

    @StateObject var viewModel = LiveChatViewModel()

    var body: some View {
        VideoChat(viewModel: viewModel)
            .ignoresSafeArea()
        .overlay(alignment: .top,content: Header)
        .overlay(alignment: .bottomTrailing, content: CameraActionView)
    }

    @ViewBuilder
    func Header() -> some View{
        HStack {
            CameraActionButton(image: .cameraReverse) {
                viewModel.toggleCamera()
            }

            Spacer()

            CameraActionButton(image: .shut, color: .red) {
                viewModel.leaveChannels()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    @ViewBuilder
    func CameraActionView() -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            CameraActionButton(image: .zoom) {
                viewModel.sendMessage(event: .zoomIn)
            }

            CameraActionButton(image: .zoomout) {
                viewModel.sendMessage(event: .zoomOut)
            }

            CameraActionButton(image: .brightness) {
                viewModel.sendMessage(event: .brightnessUp)
            }

            CameraActionButton(image: .move) {

            }

            CameraActionButton(image: .flash) {
                viewModel.sendMessage(event: .flashOn)
            }
        }
        .padding(.trailing, 20)

    }

    @ViewBuilder
    func CameraActionButton(
        image: CameraActionType,
        color: Color = Color.white.opacity(0.6),
        action : @escaping()->Void) -> some View {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

