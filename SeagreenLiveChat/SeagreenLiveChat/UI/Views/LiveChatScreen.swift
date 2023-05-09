//
//  LiveChatSharingScreen.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI
import Combine

#if targetEnvironment(simulator)
typealias CameraDisplay = Rectangle
#else
typealias CameraDisplay = CameraPreviewLayer
#endif

struct LiveChatScreen: View {

    @EnvironmentObject var viewModel: LiveChatViewModel
    
     var LocalDisplay  = CameraDisplay()
     var RemoteDisplay = RemotePreviewLayer()

    var body: some View {
        Preview()
            .onAppear {
                AgoraRtc.shared.start()
            }
//
//        GeometryReader { proxy in
//            let globalFrame = proxy.frame(in: .global)
//            let bigFrame   : CGRect = .init(origin: .zero, size: globalFrame.size)
//            let smallFrame : CGRect = .init(x: globalFrame.size.width - 100,
//                                            y: globalFrame.size.height - 140,
//                                            width: 120,
//                                            height: 200)
//
//#if targetEnvironment(simulator)
//            let fullScreenDisplay = viewModel.localCameraPosition == .rear ?
//            Rectangle().fill(Color.blue) : Rectangle().fill(Color.red)
//            let iconDisplay =  viewModel.localCameraPosition == .rear ?
//            Rectangle().fill(Color.red) : Rectangle().fill(Color.blue)
//#else
//
//            let remoteFrame = viewModel.localCameraPosition == .rear ?
//            smallFrame : bigFrame
//            let localFrame =  viewModel.localCameraPosition == .rear ?
//            bigFrame : smallFrame
//
//
//            let remotePosition: CGPoint = viewModel.localCameraPosition == .rear ?
//            CGPoint(x: globalFrame.width - 100, y: globalFrame.height - 140) : CGPoint(x: bigFrame.width / 2, y: globalFrame.height / 2)
//
//            let localPosition: CGPoint = viewModel.localCameraPosition == .rear ?
//            CGPoint(x: bigFrame.width / 2, y: bigFrame.height / 2) : CGPoint(x: localFrame.minX, y: localFrame.minY)
//#endif
//
//            Text("\(globalFrame.debugDescription)")
//                .position(x: 100, y: 200)
//
//            RemoteDisplay
//                .frame(width: remoteFrame.width, height: remoteFrame.height)
//                .position(x: remotePosition.x, y: remotePosition.y)
//
//            LocalDisplay
//                .frame(width: localFrame.width, height: localFrame.height)
//                .position(x: localPosition.x, y: localPosition.y )
//
//
//        }
        .animation(.spring(), value: viewModel.localCameraPosition)
        .task {
            await viewModel.joinChannel()
        }
    }


    @ViewBuilder
    func Preview() -> some View {
        if viewModel.localCameraPosition == .front {
            ChatPreview(LocalDisplay: LocalDisplay, RemoteDisplay: RemoteDisplay)
                .environmentObject(viewModel)
        } else {
            ShareScreenPreview(LocalDisplay: LocalDisplay, RemoteDisplay: RemoteDisplay)
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

struct RemotePreviewLayer: UIViewRepresentable {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var cameraInput: CameraControlProtocol {
        return viewModel.cameraInput
    }

    func makeUIView(context: Context) -> CustomVideoSourcePreview {
        let sourceView =  CustomVideoSourcePreview(frame: .zero)
        configRemote(uiView: sourceView)
        return sourceView
    }

    func updateUIView(_ uiView: CustomVideoSourcePreview, context: Context) {
        configRemote(uiView: uiView)
    }

    private func configRemote(uiView: CustomVideoSourcePreview) {
        switch viewModel.hostState {
        case .received(let uid):
            AgoraRtc.shared.setupRemoteVideo(uiView, uid: uid)
        case .disconnected:
            AgoraRtc.shared.setupRemoteVideo(.init(), uid: 0)
        }
    }
}



struct CameraPreviewLayer: UIViewRepresentable, Equatable {

    static func == (lhs: CameraPreviewLayer, rhs: CameraPreviewLayer) -> Bool {
        return true
    }

    @EnvironmentObject var viewModel: LiveChatViewModel

    var cameraInput: CameraControlProtocol {
        return viewModel.cameraInput
    }

    func makeUIView(context: Context) -> CustomVideoSourcePreview {
        Logger.debug("called")
        let sourceView =  CustomVideoSourcePreview(frame: .zero)
        configLocalPreview(sourceView: sourceView)
        return sourceView
    }

    func updateUIView(_ uiView: CustomVideoSourcePreview, context: Context) {
        configLocalPreview(sourceView: uiView)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    static func dismantleUIView(_ uiView: CustomVideoSourcePreview, coordinator: Coordinator) {
        Logger.debug("called")
    }

    private func configLocalPreview(sourceView: CustomVideoSourcePreview) {
        AgoraRtc.shared.setupLocalVideo(sourceView)
        cameraInput.setup(position: .front, locaPreview: sourceView)
    }

    class Coordinator: NSObject {
         var parent: CameraPreviewLayer

         init(_ parent: CameraPreviewLayer) {
             self.parent = parent
             super.init()
         }
     }

}


struct ChatPreview: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var LocalDisplay  : CameraDisplay
    var RemoteDisplay : RemotePreviewLayer

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

    var LocalDisplay : CameraDisplay
    var RemoteDisplay : RemotePreviewLayer
    
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
        RemoteDisplay
            .frame(width: 120, height: 200)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            .shadow(radius: 8)
            .environmentObject(viewModel)
    }

    @ViewBuilder
    func LocalPreview() -> some View {
        LocalDisplay
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
