//
//  NetworkErrorHandling.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 07.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UIKit
import TheGreatKit

protocol NetworkErrorDisplaying { }

extension NetworkErrorDisplaying where Self : UIViewController {
    
    func displayError() {
        self.navigationItem.prompt = "Update failed. The information can be irrelevant."
    }
    
    func hideError() {
        self.navigationItem.prompt = nil
    }
    
}

