//
//  CameraInputViewController.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 04/05/2023.
//

import Foundation
import UIKit
import AVFoundation
import AgoraRtcKit

class CameraInput: NSObject {

    var captureSession : AVCaptureSession!

    var backCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    var frontCamera : AVCaptureDevice!

    var videoOutput : AVCaptureVideoDataOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var previewSource: CustomVideoSourcePreview!

    var backCameraOn = false

    func setup(position: AVCaptureDevice.Position,
               locaPreview: CustomVideoSourcePreview) {
        self.previewSource = locaPreview
        setupAndStartCaptureSession(position: position)
    }

    private func setupAndStartCaptureSession(position: AVCaptureDevice.Position){
        DispatchQueue.global(qos: .userInitiated).async{[weak self] in
            guard let self = self else { return }
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            self.sessionPreset()
            self.setupInputs(position: position)
            self.setupOutput()
            self.setupLayer()
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }

    private func getCaptureDevice(_ position : AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devicesSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera,
                          .builtInDualCamera,
                          .builtInUltraWideCamera,
                          .builtInWideAngleCamera,
                          .builtInTrueDepthCamera],
                        mediaType: .video,
                        position: position)

        print("getCaptureDevice", devicesSession)
        let bestCaptureDevice = devicesSession.devices.first
        return bestCaptureDevice
    }

    private func setupLayer() {
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewSource.insertCaptureVideoPreviewLayer(previewLayer: self.previewLayer)
        }
    }

    private func sessionPreset() {
        if self.captureSession.canSetSessionPreset(.hd1280x720) {
            self.captureSession.sessionPreset = .hd1280x720
        } else {
            self.captureSession.sessionPreset = .high
        }
    }

    func setupInputs(position: AVCaptureDevice.Position){

        //get back camera
        if let device = getCaptureDevice(.back) {
            backCamera = device
            setContinousExposureMode()
        } else {
            fatalError("no back camera")
        }

        if let device = getCaptureDevice(.front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }

        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput

        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput

        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }

        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }

        if position == .back {
            captureSession.addInput(backInput)
        }else{
            captureSession.addInput(frontInput)
        }
    }

    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        videoOutput.videoSettings = videoSettings

        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)

        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        videoOutput.connections.first?.videoOrientation = .portrait
    }


    func switchCameraInput(){
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        videoOutput.connections.first?.videoOrientation = .portrait
        captureSession.commitConfiguration()
    }

}

extension CameraInput: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        // Get the width and height of the pixel buffer
        let width = CVPixelBufferGetWidth(cvBuffer)
        let height = CVPixelBufferGetHeight(cvBuffer)

        let ciImage =  CIImage(cvImageBuffer: cvBuffer)
        let uiImage =  UIImage(ciImage: ciImage)
        var videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.time = time
        videoFrame.strideInPixels = Int32(width)
        videoFrame.height = Int32(height)
        videoFrame.dataBuf = try? sampleBuffer.dataBuffer?.dataBytes()
        videoFrame.rotation = 0
        videoFrame.image = uiImage
        videoFrame.textureBuf = cvBuffer

        AgoraRtc.shared.agoraEngine.pushExternalVideoFrame(videoFrame)
    }
}


// Camera Command handling
extension CameraInput {


    func updateFlash(isUp: Bool) {
        guard let backCamera = backCamera,
              backCamera.hasFlash else {
            return
        }

        var nextTorch = isUp ? backCamera.torchLevel + 0.1 : backCamera.torchLevel - 0.1
        do {
            try backCamera.lockForConfiguration()
            if nextTorch > 0 && nextTorch < 1 {
                try backCamera.setTorchModeOn(level: nextTorch)
            }
        } catch {
            print("updateFlash", error)
        }
    }

    func updateExposure(isUp: Bool) {
        guard let backCamera = backCamera else {
            return
        }
        do {
            try backCamera.lockForConfiguration()
            let exposure = backCamera.exposureTargetBias
            let nextEposure = isUp ? exposure - 0.1 : exposure + 0.1
            backCamera.setExposureTargetBias(nextEposure)
            backCamera.unlockForConfiguration()
        }catch{
            print("Exposure", error)
        }
    }

    func setContinousExposureMode() {
        guard let backCamera = backCamera else {
            return
        }
        do {
            try backCamera.lockForConfiguration()
            backCamera.exposureMode = .continuousAutoExposure
            backCamera.unlockForConfiguration()
        }catch{
            print("Exposure", error)
        }
    }

    func updateZoom(isIn: Bool) {
        guard let backCamera = backCamera else {
            return
        }
        do {
            try backCamera.lockForConfiguration()
            var current = backCamera.videoZoomFactor
            var next = isIn ? current + 1 : current - 1
            if next > backCamera.minAvailableVideoZoomFactor && next < backCamera.maxAvailableVideoZoomFactor {
                backCamera.videoZoomFactor = isIn ? current + 1 : current - 1
            }
            backCamera.unlockForConfiguration()
        } catch {
            print("updateZoom", error)
        }
    }
}
