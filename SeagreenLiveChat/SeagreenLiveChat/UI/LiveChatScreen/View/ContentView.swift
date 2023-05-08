//
//  ContentView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel = LiveChatViewModel()

    var body: some View {
        CameraChatView(viewModel: viewModel)
            .ignoresSafeArea()
            .overlay(alignment: .top,content: Header)
            .overlay(alignment: .bottomLeading, content: CommandSlides)
    }


    @ViewBuilder
    func Header() -> some View {
        if viewModel.localCameraPosition == .front {
            LiveChatHeaderView()
        } else {
            HeaderStreaming()
        }
    }

    @ViewBuilder
    func LiveChatHeaderView() -> some View {
        LiveChatHeader()
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func HeaderStreaming() -> some View {
        LiveChatHeaderStreaming()
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func CommandSlides() -> some View {
        if viewModel.localCameraPosition == .rear {
            VStack(spacing: 0) {
                SlidingView(action: .flash) { value in
                    if value < 0 {
                        viewModel.sendMessage(event: .flash)
                    } else {
                        viewModel.sendMessage(event: .flashDown)
                    }
                } onReset: {

                }

                SlidingView(action: .brightness) { value in
                    if value > 0 {
                        viewModel.sendMessage(event: .brightnessUp)
                    } else {
                        viewModel.sendMessage(event: .brightnessDown)
                    }
                } onReset: {

                }

                SlidingView(action: .zoom) { value in
                    if value < 0 {
                        viewModel.sendMessage(event: .zoomIn)
                    } else {
                        viewModel.sendMessage(event: .zoomOut)
                    }
                } onReset: {

                }
            }
            .padding(.leading, 20)
            .zIndex(10)
        }
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

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

