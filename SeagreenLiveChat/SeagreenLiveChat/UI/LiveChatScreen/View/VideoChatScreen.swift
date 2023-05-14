//
//  ContentView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 30/04/2023.
//

import SwiftUI
import CallKit

public struct VideoChatScreen: View {

    @StateObject var viewModel = LiveChatViewModel()

    public init() {    }

    public var body: some View {
        ZStack {
            CameraChatView(viewModel: viewModel)
                .ignoresSafeArea()
                .overlay(alignment: .top,content: Header)
                .overlay(alignment: .bottomLeading, content: CommandSlides)
        }
    }

    @ViewBuilder
    func Header() -> some View {
        if viewModel.showSharedCommand {
            HeaderStreaming()
                .zIndex(12)
        } else {
            LiveChatHeaderView()
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
        if viewModel.showSharedCommand {
            VStack(spacing: 0) {
                SlidingView(action: .flash) { value in
                    if value < 0 {
                        viewModel.sendMessage(event: .flash)
                    } else {
                        viewModel.sendMessage(event: .flashDown)
                    }
                } onReset: {
                    viewModel.sendMessage(event: .resetFlash)
                }

                SlidingView(action: .brightness) { value in
                    if value > 0 {
                        viewModel.sendMessage(event: .brightnessUp)
                    } else {
                        viewModel.sendMessage(event: .brightnessDown)
                    }
                } onReset: {
                    viewModel.sendMessage(event: .resetExposure)
                }

                SlidingView(action: .zoom) { value in
                    if value < 0 {
                        viewModel.sendMessage(event: .zoomIn)
                    } else {
                        viewModel.sendMessage(event: .zoomOut)
                    }
                } onReset: {
                    viewModel.sendMessage(event: .resetZoom)
                }
            }
            .padding(.leading, 20)
            .zIndex(10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VideoChatScreen()
    }
}

