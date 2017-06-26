//
//  NavigationController.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class NavigationController : UINavigationController {
    
    override func viewDidLoad() {
        navigationBar <- {
            $0.barStyle = .default
            $0.tintColor = UIColor(named: .navigationBackground)
        }
    }
    
}
