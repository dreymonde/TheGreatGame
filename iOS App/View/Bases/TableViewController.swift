//
//  TableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class TableViewController : UITableViewController {
    
    deinit {
        print("Deinit \(self)")
    }
        
}

extension TableViewController : NetworkErrorDisplaying {
    
    func displayNetworkUpdateError(error: Error) {
        displayError()
    }
    
    func hideNetworkUpdateError() {
        hideError()
    }
    
}
