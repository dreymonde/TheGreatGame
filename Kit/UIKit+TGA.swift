//
//  TGG+UIImageView.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

extension UIImageView {
    
    public func setImage(_ newImage: UIImage?, afterDownload: Bool) {
        let old = self.image
        self.image = newImage
        if afterDownload && newImage != nil && old == nil {
            fadeTransit(duration: 0.2)
        }
    }
    
}

extension UIView {
    
    public func fadeTransit(duration: TimeInterval = 0.2) {
        let transition = CATransition() <- {
            $0.duration = duration
            $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            $0.type = kCATransitionFade
        }
        self.layer.add(transition, forKey: nil)
    }
    
}

extension IndexPath {
    
    public static func start(ofSection section: Int) -> IndexPath {
        return IndexPath(row: NSNotFound, section: section)
    }
    
}

extension UIFont {
    
    public func monospacedNumbers() -> UIFont {
        return UIFont(descriptor: fontDescriptor.monospacedNumbers(), size: 0)
    }
    
}

extension UIFontDescriptor {
    
    fileprivate func monospacedNumbers() -> UIFontDescriptor {
        let featureSettings = [UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                               UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]
        return self.addingAttributes([UIFontDescriptor.AttributeName.featureSettings: [featureSettings]])
    }
    
}
