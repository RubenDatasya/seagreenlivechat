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


    func decorate(localView: UIView, in view: UIView) {
        localView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate ([
            localView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            localView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            localView.widthAnchor.constraint(equalToConstant: 120),
            localView.heightAnchor.constraint(equalToConstant: 200),
        ])
        localView.shadowView(parent: view)
        localView.setBorder(borderColor: Color.pink.cgColor)
    //    localView.transform = CGAffineTransform(scaleX: 0, y: 0)
    //    localView.transform = CGAffineTransform(translationX: -400, y: 0)
    }

    func decorate(remoteView: UIView, in view: UIView) {
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate ([
            remoteView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            remoteView.widthAnchor.constraint(equalTo: view.widthAnchor),
            remoteView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
      //  remoteView.transform = CGAffineTransform(scaleX: 0, y: 0)
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
        addSubview(cornerContainer)

        cornerContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate ([
            cornerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cornerContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            cornerContainer.widthAnchor.constraint(equalTo: widthAnchor),
            cornerContainer.heightAnchor.constraint(equalTo: heightAnchor),
        ])
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
        borderWidth: CGFloat = 1,
        borderColor: CGColor? = UIColor.black.cgColor) {
            self.layer.borderColor = borderColor
            self.layer.borderWidth = borderWidth
        }
}
