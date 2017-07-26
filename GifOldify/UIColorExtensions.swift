//
//  UIColorExtensions.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(r: Int, g:Int , b:Int) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1.0)
    }
    
    class func backgroundYellow() -> UIColor {
        return UIColor(r: 255, g: 243, b: 92)
    }
    
    class func backgroundRed() -> UIColor {
        return UIColor(r: 255, g: 102, b: 102)
    }
    
    class func backgroundPurple() -> UIColor {
        return UIColor(r: 153, g: 51, b: 255)
    }
    
    class func backgroundGreen() -> UIColor {
        return UIColor(r: 0, g: 255, b: 153)
    }
    
    class func backgroundBlue() -> UIColor {
        return UIColor(r: 0, g: 204, b: 255)
    }
}
