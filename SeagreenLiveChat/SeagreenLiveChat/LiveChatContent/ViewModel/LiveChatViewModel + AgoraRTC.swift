//
//  LiveChatViewModel + AgoraVideoFrameDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation
import AgoraRtcKit


extension LiveChatViewModel: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        newHostEvent.send(uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError AgoraErrorCode", errorCode.rawValue)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        print("didOccur AgoraEncryptionErrorType", errorType.rawValue)
    }

}


extension LiveChatViewModel: AgoraVideoFrameDelegate {
    // Occurs each time the SDK receives a video frame captured by the local camera
    func onCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
      //  print("onCapture")
        return true
    }

    // Occurs each time the SDK receives a video frame captured by the screen
    func onScreenCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        // Choose whether to ignore the current video frame if the pre-processing fails
        return false
    }
    // Occurs each time the SDK receives a video frame sent by the remote user
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        // Get the pixel buffer from the AgoraOutputVideoFrame
        guard let pixelBuffer = videoFrame.pixelBuffer else {
            return true
        }

        // Lock the pixel buffer to make it accessible in memory
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        // Get the image information from the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerPixel = 4
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Calculate the brightness adjustment factor
        let brightness: Float = localState.brightness

        // Modify the pixel buffer data to adjust the brightness
        for y in 0..<height {
            let row = baseAddress! + y * bytesPerRow
            for x in 0..<width {
                let pixel = row.advanced(by: x * bytesPerPixel).assumingMemoryBound(to: UInt8.self)

                // Convert the pixel values to floats between 0 and 1
                let red = Float(pixel[0]) / 255.0
                let green = Float(pixel[1]) / 255.0
                let blue = Float(pixel[2]) / 255.0

                // Apply the brightness adjustment factor
                let adjustedRed = min(max(red * brightness, 0), 1)
                let adjustedGreen = min(max(green * brightness, 0), 1)
                let adjustedBlue = min(max(blue * brightness, 0), 1)

                // Convert the adjusted pixel values back to UInt8 format
                pixel[0] = UInt8(adjustedRed * 255.0)
                pixel[1] = UInt8(adjustedGreen * 255.0)
                pixel[2] = UInt8(adjustedBlue * 255.0)
            }
        }


        // Unlock the pixel buffer to release the memory lock
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        videoFrame.pixelBuffer = pixelBuffer
        return true
    }


    // Indicate the video frame mode of the observer
    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        // The process mode of the video frame: readOnly, readWrite
        return AgoraVideoFrameProcessMode.readWrite
    }

    // Sets the video frame type preference
    func getVideoFormatPreference() -> AgoraVideoFormat {
        // Video frame format: I420, BGRA, NV21, RGBA, NV12, CVPixel, I422, Default
        return AgoraVideoFormat.cvPixelBGRA
    }

    // Sets the frame position for the video observer
    func getObservedFramePosition() -> AgoraVideoFramePosition {
        // Frame position: postCapture, preRenderer, preEncoder
        return AgoraVideoFramePosition.preRenderer
    }
}
