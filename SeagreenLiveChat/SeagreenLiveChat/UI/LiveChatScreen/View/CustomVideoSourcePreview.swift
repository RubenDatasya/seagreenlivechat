//
//  CustomVideoSourcePreview.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 07/05/2023.
//

import Foundation
import AVFoundation
import UIKit

class CustomVideoSourcePreview : UIView {

    private var previewLayer: AVCaptureVideoPreviewLayer?

    func insertCaptureVideoPreviewLayer(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()

        previewLayer.frame = bounds
        layer.insertSublayer(previewLayer, below: layer.sublayers?.first)
        self.previewLayer = previewLayer
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        previewLayer?.frame = bounds
    }
}
