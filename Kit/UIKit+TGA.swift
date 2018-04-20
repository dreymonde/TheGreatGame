//
//  TGG+UIImageView.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

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
