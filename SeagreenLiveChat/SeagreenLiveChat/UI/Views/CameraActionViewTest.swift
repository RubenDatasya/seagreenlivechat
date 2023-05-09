//
//  CameraActionViewTest.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import SwiftUI

struct CameraActionViewTest: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var body: some View {
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

struct CameraActionViewTest_Previews: PreviewProvider {
    static var previews: some View {
        CameraActionViewTest()
            .environmentObject(LiveChatViewModel())
    }
}
