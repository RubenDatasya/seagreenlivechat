//
//  LiveChatHeaderStreaming.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI

struct LiveChatHeaderStreaming: View {

    @EnvironmentObject var viewModel: LiveChatViewModel

    var body: some View {
        ZStack {
            RemoteHeader {
                viewModel.toggleCamera()
            }

            HStack {
                SoundButton { isMuted in

                }
                .padding(.init(top: 7, leading: 20, bottom: 0, trailing: 0))

                Spacer()
            }
        }
    }
}

struct LiveChatHeaderStreaming_Previews: PreviewProvider {
    static var previews: some View {
        LiveChatHeaderStreaming()
            .environmentObject(LiveChatViewModel())
    }
}
