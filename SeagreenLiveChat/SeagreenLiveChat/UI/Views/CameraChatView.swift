//
//  CameraChatView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import SwiftUI

struct CameraChatView: View {

    @ObservedObject var viewModel: LiveChatViewModel

    var body: some View {
#if targetEnvironment(simulator)
        Rectangle()
            .fill(Color.gray.opacity(0.5))
#else
        VideoChat(viewModel: viewModel)
#endif
    }
}

struct CameraChatView_Previews: PreviewProvider {
    static var previews: some View {
        CameraChatView(viewModel: .init())
    }
}
