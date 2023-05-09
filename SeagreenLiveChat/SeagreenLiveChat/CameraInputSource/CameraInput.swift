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

protocol CameraControlProtocol {

    func setup(position: AVCaptureDevice.Position,
               locaPreview: CustomVideoSourcePreview)
    func updateFlash(isUp: Bool)
    func updateExposure(isUp: Bool)
    func updateZoom(isIn: Bool)
    func switchCameraInput()
    func focus(at: CGPoint)
}

protocol ResetCameraControlProtocol {

    func setup(position: AVCaptureDevice.Position,
               locaPreview: CustomVideoSourcePreview)
    func resetFlash()
    func resetExposure()
    func resetZoom()
    func resetFocus()
}

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

        var bestCaptureDevice : AVCaptureDevice?
        if position == .back {
            bestCaptureDevice = devicesSession.devices.first(where: \.isFocusPointOfInterestSupported)
        }else{
            bestCaptureDevice = devicesSession.devices.first
        }
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

    private func removeInputs() {
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }
    }

    private func setupInputs(position: AVCaptureDevice.Position){
        //get back camera
        if let device = getCaptureDevice(.back) {
            backCamera = device
            setContinousExposureMode(device: backCamera)
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

    private func setContinousExposureMode(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            device.exposureMode = .continuousAutoExposure
            device.unlockForConfiguration()
        }catch{
            Logger.severe("exposure", error: error)
        }
    }

    private func setupOutput(){
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

    private func prepareForChange(change: @escaping (AVCaptureDevice) throws -> Void) {
        guard let backCamera = backCamera else {
            return
        }
        do {
            try backCamera.lockForConfiguration()
            try change(backCamera)
            backCamera.unlockForConfiguration()
        } catch {
            Logger.severe("prepareForChange", error: error)
        }
    }
}

extension CameraInput: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let width = CVPixelBufferGetWidth(cvBuffer)
        let height = CVPixelBufferGetHeight(cvBuffer)
        let ciImage =  CIImage(cvImageBuffer: cvBuffer)
        let uiImage =  UIImage(ciImage: ciImage)

        let videoFrame = AgoraVideoFrame()
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
extension CameraInput: CameraControlProtocol {

    func setup(position: AVCaptureDevice.Position, locaPreview: CustomVideoSourcePreview) {
        guard previewSource == nil else { return }
        self.previewSource = locaPreview
        setupAndStartCaptureSession(position: position)
    }

    func focus(at point: CGPoint) {
        prepareForChange { device in
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
        }
    }

    func updateFlash(isUp: Bool) {
        prepareForChange { device in
            let nextTorch = isUp ? device.torchLevel + 0.1 : device.torchLevel - 0.1
            if nextTorch > 0 && nextTorch < 1 {
                try device.setTorchModeOn(level: nextTorch)
            }
        }
    }

    func updateExposure(isUp: Bool) {
        prepareForChange { device in
            let exposure = device.exposureTargetBias
            let nextEposure = isUp ? exposure - 0.1 : exposure + 0.1
            device.setExposureTargetBias(nextEposure)
        }
    }

    func updateZoom(isIn: Bool) {
        prepareForChange { device in
            let current = device.videoZoomFactor
            let next = isIn ? current + 1 : current - 1
            if next > device.minAvailableVideoZoomFactor && next < device.maxAvailableVideoZoomFactor {
                device.videoZoomFactor = isIn ? current + 1 : current - 1
            }
        }
    }

    func switchCameraInput(){
        guard let captureSession = captureSession else { return }
            captureSession.beginConfiguration()
            if backCameraOn {
                removeInputs()
                captureSession.addInput(frontInput)
                backCameraOn = false
            } else {
              removeInputs()
                captureSession.addInput(backInput)
                backCameraOn = true
            }
            videoOutput.connections.first?.videoOrientation = .portrait
            captureSession.commitConfiguration()
    }
}


extension CameraInput: ResetCameraControlProtocol {
    func resetFlash() {
        prepareForChange { device in
            try device.setTorchModeOn(level: 0)
        }
    }

    func resetExposure() {
        prepareForChange { device in
            device.exposureMode = .continuousAutoExposure
        }
    }

    func resetZoom() {
        prepareForChange { device in
            device.videoZoomFactor = device.minAvailableVideoZoomFactor
        }
    }

    func resetFocus() {
        prepareForChange { device in
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.focusMode = .continuousAutoFocus
        }
    }


}
