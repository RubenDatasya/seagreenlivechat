//
//  LiveChatHeader.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI

struct LiveChatHeader: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var body: some View {
        HStack(spacing: 23) {

            Button {
                viewModel.toggleAudio()
            } label: {
                Images.unmute
                    .foregroundColor(.white)
            }
            .padding(.leading, Values.Dimensions.leading)


            Button {
                viewModel.toggleCamera()
            } label: {
                Images.cameraReverse
                    .foregroundColor(.white)
            }

            Spacer()

            DemoCallButton()

            Button {
                viewModel.endCall()
            } label: {
                Text("End Call")
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(width: Values.Dimensions.width, height: Values.Dimensions.height)
            .background(Colors.redStop)
            .clipShape(RoundedRectangle(cornerRadius: Values.Dimensions.cornerRadius))
            .padding(.trailing, Values.Dimensions.padding)
        }
        .frame(height: Values.Dimensions.viewHeight)
        .background(Colors.primary)
    }

    @ViewBuilder
    func DemoCallButton() -> some View {
        if LiveChat.shared.isDemo() {
            Button {
                viewModel.startCall()
            } label: {
                Images.phoneConnection
                    .foregroundColor(Color.white)
            }
        }
    }
}

fileprivate enum Values {
    enum Dimensions {
        static let viewHeight   : CGFloat       = 116
        static let spacing      : CGFloat       = 23
        static let leading      : CGFloat       = 23
        static let trailing     : CGFloat       = 23
        static let width        : CGFloat       = 97
        static let height        : CGFloat      = 40
        static let cornerRadius : CGFloat       = 4
        static let padding      : CGFloat       = 14
    }
}

struct LiveChatHeader_Previews: PreviewProvider {
    static var previews: some View {
        LiveChatHeader()
            .environmentObject(LiveChatViewModel())
    }
}
