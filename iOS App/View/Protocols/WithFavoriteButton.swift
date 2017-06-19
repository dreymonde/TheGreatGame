//
//  WithFavoriteButton.swift
//  TheGreatGame
//
//  Created by Олег on 19.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

protocol WithFavoriteButton : class {
    
    weak var favoriteButton: UIButton! { get }
    
    var isFavorite: () -> (Bool) { get }
    var updateFavorite: (Bool) -> () { get }
    
}

extension WithFavoriteButton {
    
    func didPressFavorite() {
        favoriteButton.isSelected = !favoriteButton.isSelected
        updateFavorite(favoriteButton.isSelected)
    }
    
    func configure(favoriteButton: UIButton) {
        favoriteButton.isSelected = isFavorite()
    }
    
}
