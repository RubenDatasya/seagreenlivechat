//
//  MoveButton.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 07/05/2023.
//

import SwiftUI


enum Corners: Int, CaseIterable {
    case top
    case right
    case bottom
    case left

    var image: Image {
        switch self {
        case .top:
            return Images.arrowTop
        case .right:
            return  Images.arrowLeft
        case .bottom:
            return Images.arrowBottom
        case .left:
            return Images.arrowRight
        }
    }

}


struct MoveButton: View {


    var body: some View {
        MoveContent()
    }

}

struct MoveContent: View {
    let corners =  Corners.allCases
    let numberOfViews = 4 // 4 views, one for each quadrant

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary)

            ForEach(0..<numberOfViews) { index in
                let corner = corners[index]
                CircleView(index: index, total: numberOfViews, corner: corner)
                    .rotationEffect(Angle(degrees: Double(index) * 90))
            }
        }
    }
}

struct CircleView: View {
    let index: Int
    let total: Int
    let radius: CGFloat = 150
    let corner: Corners

    var body: some View {

        corner.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
        .rotationEffect(Angle(degrees: 360 / Double(total) * Double(index)))
        .offset(y: -radius / 2)
    }
}


fileprivate struct Cornered: View {
    let index: Int
    let total: Int
    let radius: CGFloat = 120

    var body: some View {

        RoundedCorner()
            .stroke(style: .init(lineWidth: 60, lineCap: .round))
            .frame(width: radius, height: radius)
            .rotationEffect(Angle(degrees: 360 / Double(total) * Double(index)))
            .offset(y: -radius / 2)

    }
}


fileprivate struct RoundedCorner: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center: CGPoint = .init(x: rect.width / 2, y: rect.height / 2)

        path.move(to:CGPoint(x: center.x - 60, y: center.y + 60))
        path.addLine(to: center)
        path.addLine(to:CGPoint(x: center.x + 60, y: center.y + 60))

        return path
    }
}

struct MoveButton_Previews: PreviewProvider {
    static var previews: some View {
        MoveButton()
    }
}
