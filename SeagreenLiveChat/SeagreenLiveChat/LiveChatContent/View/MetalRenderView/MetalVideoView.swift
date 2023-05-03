//
//  MetalVideoView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation
import UIKit

class MetalVideoView: UIView {

    var liveChatViewModel: LiveChatViewModel! {
        didSet {
            self.videoView.liveChatViewModel = liveChatViewModel
        }
    }
    @IBOutlet weak var placeholder: UILabel!
    @IBOutlet weak var videoView: AgoraMetalRender!
    @IBOutlet weak var infolabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setPlaceholder(text:String) {
        placeholder.text = text
    }

    func setInfo(text:String) {
        infolabel.text = text
    }
}
