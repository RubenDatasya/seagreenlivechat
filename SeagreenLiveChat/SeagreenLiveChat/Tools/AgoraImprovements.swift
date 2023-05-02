//
//  AgoraImprovements.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 02/05/2023.
//

import Foundation

protocol AgoraQualityImprovementProtocol {
    var name: String { get }
    var `extension`: String { get }
    var key: String { get }
    var value: String { get }
}

struct AgoraColorEnhancement: AgoraQualityImprovementProtocol {
     let name = "agora"
     let `extension` = "beauty"
     let key = "color_enhance_option"
     let value = "enable"
}

struct AgoraUnderExposed: AgoraQualityImprovementProtocol {
     let name = "agora"
     let `extension` = "beauty"
     let key = "lowlight_enhance_option"
     let value = "level"
}

struct AgoraVideoDenoising: AgoraQualityImprovementProtocol {
     let name = "agora"
     let `extension` = "beauty"
     let key = "video_denoiser_option"
     let value = "level"
}
