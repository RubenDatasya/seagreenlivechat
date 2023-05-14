//
//  Audio.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 14/05/2023.
//

import Foundation
import AVFoundation

func configureAudioSession() {
  print("Configuring audio session")
  let session = AVAudioSession.sharedInstance()
  do {
    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
  } catch (let error) {
    print("Error while configuring audio session: \(error)")
  }
}

func startAudio() {
  print("Starting audio")
    do {
       try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print(error)
    }
}

func stopAudio() {
  print("Stopping audio")
    do {
        try AVAudioSession.sharedInstance().setActive(false)
    } catch {
        print(error)
    }
}
