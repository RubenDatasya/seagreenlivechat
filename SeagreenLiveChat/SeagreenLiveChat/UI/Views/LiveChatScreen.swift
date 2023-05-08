//
//  LiveChatSharingScreen.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI
import Combine

#if os(simulator)
typealias CameraDisplay = RoundedRectangle
#else
typealias CameraDisplay = CameraPreviewLayer
#endif


struct LiveChatScreen: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    @State var LocalDisplay = CameraDisplay(isRemote: false)
    @State var RemoteDisplay = CameraDisplay(isRemote: true)

    var body: some View {
        Preview()
            .environmentObject(viewModel)
            .onAppear {
                AgoraRtc.shared.start()
            }
            .task {
                await viewModel.joinChannel()
            }
    }

    @ViewBuilder
    func Preview() -> some View {
        if viewModel.localCameraPosition == .front {
            ChatPreview(LocalDisplay: $LocalDisplay, RemoteDisplay: $RemoteDisplay)
                .environmentObject(viewModel)
        }else {
            ShareScreenPreview(LocalDisplay: $LocalDisplay, RemoteDisplay: $RemoteDisplay)
                .environmentObject(viewModel)
        }
    }
}

struct LiveChatScreen_Previews: PreviewProvider {
    static var previews: some View {
        LiveChatScreen()
            .environmentObject(LiveChatViewModel())
    }
}


struct CameraPreviewLayer: UIViewRepresentable {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var cameraInput: CameraControlProtocol {
        return viewModel.cameraInput
    }

    var isRemote: Bool = false

    func makeUIView(context: Context) -> CustomVideoSourcePreview {
        let sourceView =  CustomVideoSourcePreview(frame: .zero)
        configLocalPreview(sourceView: sourceView)
        return sourceView
    }

    func updateUIView(_ uiView: CustomVideoSourcePreview, context: Context) {
        configRemote(uiView: uiView)
    }

    private func configLocalPreview(sourceView: CustomVideoSourcePreview) {
        if !isRemote {
            AgoraRtc.shared.setupLocalVideo(sourceView)
            cameraInput.setup(position: .front, locaPreview: sourceView)
        }
    }

    private func configRemote(uiView: CustomVideoSourcePreview) {
        guard isRemote else { return }
        switch viewModel.hostState {
        case .received(let uid):
            AgoraRtc.shared.setupRemoteVideo(uiView, uid: uid)
        case .disconnected:
            AgoraRtc.shared.setupRemoteVideo(.init(), uid: 0)
        }
    }
}


struct ChatPreview: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    @Binding var LocalDisplay : CameraDisplay
    @Binding var RemoteDisplay : CameraDisplay

    var body: some View {
        RemotePreview()
            .overlay(alignment: .top,content: LiveChatHeaderView)
            .overlay(alignment: .bottomLeading,content: LocalPreview)
    }

    @ViewBuilder
    func LiveChatHeaderView() -> some View {
        LiveChatHeader()
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func LocalPreview() -> some View {
        LocalDisplay
            .frame(width: 120, height: 200)
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            .shadow(radius: 8)
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func RemotePreview() -> some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            RemoteDisplay
                .frame(width: frame.width, height: frame.height)
                .environmentObject(viewModel)
        }
    }
}

struct ShareScreenPreview: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    @Binding var LocalDisplay : CameraDisplay
    @Binding var RemoteDisplay : CameraDisplay
    
    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            LocalPreview()
                .frame(width: frame.width, height: frame.height)
                .ignoresSafeArea()
                .overlay(alignment: .top,content: HeaderStreaming)
                .overlay(alignment: .bottomLeading, content:CommandSlides)
                .overlay(alignment: .bottomTrailing, content: RemotePreview)
                .environmentObject(viewModel)
        }
    }


    @ViewBuilder
    func HeaderStreaming() -> some View {
        LiveChatHeaderStreaming()
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func RemotePreview() -> some View {
        LocalDisplay
            .frame(width: 120, height: 200)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            .shadow(radius: 8)
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func LocalPreview() -> some View {
        RemoteDisplay
            .environmentObject(viewModel)
    }


    @ViewBuilder
    func CommandSlides() -> some View {
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


protocol ObserveCameraCommandsProtocol {
    var subscriptions: Set<AnyCancellable> { get set }
    func observeAlert()
    func observeCamera()
    func observeNewHost()
    func observeZoom()
    func observeFlash()
    func observeExposure()
}
