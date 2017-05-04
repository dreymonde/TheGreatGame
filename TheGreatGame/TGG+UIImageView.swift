//
//  TGG+UIImageView.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func setImage(_ newImage: UIImage?, afterDownload: Bool) {
        let old = self.image
        self.image = newImage
        if afterDownload && newImage != nil && old == nil {
            let transition = CATransition() <- {
                $0.duration = 0.2
                $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                $0.type = kCATransitionFade
            }
            self.layer.add(transition, forKey: nil)
        }
    }
    
}
