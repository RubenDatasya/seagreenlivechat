//
//  SlidingView.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 07/05/2023.
//

import SwiftUI

enum SlideAction {
    case brightness
    case zoom
    case flash

    var image: Image {
        switch self {
        case .flash:
            return Images.flashOn
        case .brightness:
            return Images.brightness
        case .zoom:
            return Images.zoomBtn
        }
    }
}

struct SlidingView: View {

    var action: SlideAction
    @State var translation: CGSize = .zero
    @State var showBackground: Bool = false
    var onTranslationEvent: (CGFloat) -> Void
    var onReset: ()-> Void

    var body: some View {
        ZStack {
            Images.slidingArea
                .overlay(alignment: .top, content: PlusIcon)
                .overlay(alignment: .bottom, content: MinusIcon)
                .opacity(showBackground ? 1 : 0)

            action.image
                .onLongPressGesture(perform: onReset)
                .onDrag(with: $translation)
        }
        .onChange(of: translation.height) {newValue in
            showBackground = translation.height != 0
            onTranslationEvent(newValue)
        }
    }

    @ViewBuilder
    func PlusIcon() -> some View {
        Images.plus
            .slidingIcons()
    }

    @ViewBuilder
    func MinusIcon() -> some View {
        Images.minus
            .slidingIcons()
    }
}

fileprivate struct DragModifier: ViewModifier {
    
    @Binding var translation: CGSize
    
    func body(content: Content) -> some View {
        content
            .offset(translation)
            .gesture(
                DragGesture(minimumDistance: 0.5)
                    .onChanged { value in
                        if value.translation.height < abs(Values.Size.maxHeight)  {
                            translation.height = value.translation.height / 3
                        }
                    }
                    .onEnded{ _ in
                        translation = .zero
                    }
            )
    }
}

fileprivate extension View {
    func onDrag(with value: Binding<CGSize>) -> some View {
        modifier(DragModifier(translation: value))
    }
}

fileprivate extension Image {
    func slidingIcons() -> some View {
        let size = Values.Size.iconSize
        return self
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .padding([.top, .bottom], Values.Size.iconPadding)
    }
}

fileprivate enum Values {
    enum Size {
        static let maxHeight: CGFloat = 115
        static let iconSize: CGFloat = 16
        static let iconPadding: CGFloat = 10
    }
}

struct SlidingView_Previews: PreviewProvider {
    static var previews: some View {
        SlidingView(action: .brightness, onTranslationEvent: {_ in  }, onReset: { })
    }
}
