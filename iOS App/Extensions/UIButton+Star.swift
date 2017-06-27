//
//  UIButton+Star.swift
//  TheGreatGame
//
//  Created by Олег on 19.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

extension UIButton {
        
    func asStarButton() {
        let emptyStarImage = #imageLiteral(resourceName: "Unfilled_Star")
        let fullStarImage = #imageLiteral(resourceName: "Filled_Star")
        
        self <- {
            $0.setImage(emptyStarImage, for: UIControlState.normal)
            $0.setImage(fullStarImage, for: UIControlState.selected)
        }
    }
    
}
