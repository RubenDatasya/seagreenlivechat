//
//  ViewControllerDecorator.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 01/05/2023.
//

import Foundation
import UIKit
import SwiftUI

class ViewControllerDecorator {

    func decorate(preview: UIView, in view: UIView, isFullScreen: Bool =  false) {
        preview.translatesAutoresizingMaskIntoConstraints = true
        let size = CGSize(width: 120, height: 200)

        UIView.animate(withDuration: 0.5) {
            var newFrame: CGRect
            if isFullScreen {
                newFrame = view.frame
            } else {
                newFrame = CGRect(origin: .init(x: view.frame.width - 140, y: view.frame.height - 240), size: size)
                view.bringSubviewToFront(preview)
            }
            preview.frame = newFrame
        }

        preview.shadowView(parent: view)
        preview.rounded()
    }

    func decorate(view: UIView, with selector : Selector) {
        let tapgesture =  UITapGestureRecognizer(target: view, action: selector)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapgesture)
    }
}

extension UIView {

    func animate(duration: TimeInterval = 0.5, delay: TimeInterval = 0, animations: @escaping (UIView) -> Void) {
        UIView.animate(withDuration: duration, delay: delay) {
            animations(self)
        }
    }

    func rounded(cornerRadius: CGFloat = 12) {
        let cornerContainer =  UIView(frame: self.frame)
        cornerContainer.layer.cornerRadius =  cornerRadius
        cornerContainer.layer.masksToBounds = true
//        addSubview(cornerContainer)
//
//        cornerContainer.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate ([
//            cornerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
//            cornerContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
//            cornerContainer.widthAnchor.constraint(equalTo: widthAnchor),
//            cornerContainer.heightAnchor.constraint(equalTo: heightAnchor),
//        ])
    }

    func shadowView(
        parent: UIView,
        shadowOpacity: Float = 0.6,
        shadowOffset: CGSize =  .init(width: 8, height: 8)
    ) {

        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowRadius = 8
    }

    func setBorder(
        borderWidth: CGFloat = 2,
        borderColor: CGColor?) {
            self.layer.borderColor = borderColor
            self.layer.borderWidth = borderWidth
        }
}
