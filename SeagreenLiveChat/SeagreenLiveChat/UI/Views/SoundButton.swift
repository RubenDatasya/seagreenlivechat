//
//  SoundButton.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 07/05/2023.
//

import SwiftUI



enum SoundState {
    case on
    case off

    var image: Image {
        switch self {
        case .on:
            return Images.unmute
        case .off:
            return Images.speakerOff
        }
    }
}

struct SoundButton: View {


    @State var speakerState: SoundState = .on
    var onMute: (Bool) -> Void

    var body: some View {
        Button {
            toggleState()
            onMute(speakerState == .off)
        } label: {
            speakerState.image
                .foregroundColor(Color.white)
                .frame(width: 56, height: 56)
                .background(Colors.transparentGray)
                .clipShape(Circle())
        }
    }

    func toggleState() {
        if speakerState == .off {
            speakerState = .on
        }else {
            speakerState = .off
        }
    }
}


struct SoundButton_Previews: PreviewProvider {
    static var previews: some View {
        SoundButton(onMute: { _ in })
    }
}
