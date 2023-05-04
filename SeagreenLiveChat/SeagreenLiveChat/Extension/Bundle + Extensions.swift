//
//  Bundle + Extensions.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

import Foundation
import UIKit

extension Bundle {

    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }

        fatalError("Could not load view with type " + String(describing: type))
    }
    
}

extension UIViewController {

    static func instantiate<T: UIViewController>() -> T {
        let identifier = String(describing: T.self)
        return UIStoryboard(name: "ChatStoryboard", bundle: nil)
            .instantiateViewController(withIdentifier: identifier) as! T
    }
}
