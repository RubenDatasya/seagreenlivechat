//
//  VideoChat.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation
import SwiftUI

struct VideoChat: UIViewControllerRepresentable {

    @ObservedObject var viewModel: LiveChatViewModel

    func makeUIViewController(context: Context) -> ViewController {
        let vc: ViewController = .init(viewModel: viewModel)
        return vc
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {

    }

    typealias UIViewControllerType = ViewController
}
