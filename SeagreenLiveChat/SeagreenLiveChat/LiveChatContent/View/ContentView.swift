//
//  ContentView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
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

struct ContentView: View {

    @StateObject var viewModel = LiveChatViewModel()

    var body: some View {
        Camera()
        .ignoresSafeArea()
        .overlay(alignment: .top,content: Header)
        .overlay(alignment: .bottomTrailing, content: CameraActionView)
    }


    @ViewBuilder
    func Camera() -> some View {
#if targetEnvironment(simulator)
        Rectangle()
            .fill(Color.purple)
#else
        VideoChat(viewModel: viewModel)
#endif
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
        ScrollView {
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

                CameraActionButton(image: .brightnessDown) {
                    viewModel.sendMessage(event: .brightnessDown)
                }

                CameraActionButton(image: .move) {

                }

                CameraActionButton(image: .flash) {
                    viewModel.sendMessage(event: .flash)
                }

                CameraActionButton(image: .flashDown) {
                    viewModel.sendMessage(event: .flashDown)
                }
            }
        }
        .frame(height: 300)
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

