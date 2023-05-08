//
//  RemoteHeader.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 07/05/2023.
//

import SwiftUI

struct RemoteHeader: View {

    private let twelve = Values.Dimensions.square
    private let six = Values.Dimensions.six
    private let eight = Values.Dimensions.eight

    var onStopTapped: () -> Void

    var body: some View {
        ZStack {
            BackgroundLayer()
            HeaderContent()
        }
        .frame(width: Values.Dimensions.frameWidth,
               height: Values.Dimensions.frameHeight)
        .cornerRadius(Values.Dimensions.frameCornerRadius)
    }

    @ViewBuilder
    func BackgroundLayer() -> some View {
        Rectangle()
            .fill(Colors.primary)
    }

    @ViewBuilder
    func HeaderContent() -> some View {
        VStack {
            Title()
            StopButton()
        }
    }

    @ViewBuilder
    func Title() -> some View {
        Text(Values.Texts.content)
            .font(.system(size: twelve))
            .foregroundColor(Color.white)
    }

    @ViewBuilder
    func StopButton() -> some View {
        Button {
            onStopTapped()
        } label: {
            HStack {
                Rectangle()
                    .fill(Colors.redStop)
                    .frame(width: twelve, height: twelve)

                Text(Values.Texts.stopContent)
                    .foregroundColor(Colors.redStop)
                    .bold()
            }
            .padding(EdgeInsets(top: six, leading: eight, bottom: six, trailing: eight))
            .overlay(RoundedRectangle(
                cornerRadius: Values.Dimensions.frameCornerRadius)
                .stroke(lineWidth: 1)
                .foregroundColor(Colors.redStop)
            )
        }

    }
}


fileprivate enum Values {
    enum Dimensions {
        static let frameWidth           : CGFloat = 197
        static let frameHeight          : CGFloat = 70
        static let frameCornerRadius    : CGFloat = 4
        static let square               : CGFloat = 12
        static let six                 : CGFloat = 6
        static let eight                : CGFloat = 8
    }

    enum Texts {
        static let content      : String = "You are in remote camera mode"
        static let stopContent  : String = "STOP REMOTE"
    }
}


struct RemoteHeader_Previews: PreviewProvider {
    static var previews: some View {
        RemoteHeader(onStopTapped: { })
    }
}
