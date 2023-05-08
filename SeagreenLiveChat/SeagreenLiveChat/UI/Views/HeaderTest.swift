//
//  HeaderTest.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI

struct HeaderTest: View {

    @ObservedObject var viewModel: LiveChatViewModel

    var body: some View {
        HStack {
            CameraActionButton(image: .cameraReverse) {
                viewModel.toggleCamera()
            }

            Spacer()

            CameraActionButton(color: .red, image: .shut) {
                viewModel.leaveChannels()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct HeaderTest_Previews: PreviewProvider {
    static var previews: some View {
        HeaderTest(viewModel: .init())
    }
}
