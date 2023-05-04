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
import VideoToolbox
import Accelerate.vImage
import CoreMedia
import CoreVideo
import simd

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
        DispatchQueue.global(qos: .userInitiated).async{
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(.hd1280x720) {
                self.captureSession.sessionPreset = .hd1280x720
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            self.setupInputs(position: position)
            self.setupOutput()
            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewSource.insertCaptureVideoPreviewLayer(previewLayer: self.previewLayer)
            }
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }

    private func getCaptureDevice(_ position : AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devicesSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: position)
        let bestCaptureDevice = devicesSession.devices.first
        return bestCaptureDevice
    }

    func setupInputs(position: AVCaptureDevice.Position){

        //get back camera
        if let device = getCaptureDevice(.back) {
            backCamera = device
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
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]

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

        let videoFrame = AgoraVideoFrame()
        videoFrame.format = AgoraVideoBitrateStandard
        videoFrame.time = time
//        videoFrame.strideInPixels = Int32(width)
//        videoFrame.height = Int32(height)
//        videoFrame.dataBuf = try? sampleBuffer.dataBuffer?.dataBytes()
        videoFrame.rotation = 0
        videoFrame.image = uiImage
        videoFrame.textureBuf = cvBuffer

        AgoraRtc.shared.pushFrame(videoFrame)
    }
}


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
