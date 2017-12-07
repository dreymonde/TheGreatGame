//
//  NetworkErrorHandling.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 07.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UIKit

protocol NetworkErrorDisplaying { }

extension NetworkErrorDisplaying where Self : UIViewController {
    
    
    
}

final class NetworkErrorDisplayer {
    
    init() { }
    
    func displayError(on viewController: UIViewController) {
        viewController.navigationItem.prompt = "Update failed. The information can be irrelevant."
    }
    
    func hideError(on viewController: UIViewController) {
        viewController.navigationItem.prompt = nil
    }
    
}
