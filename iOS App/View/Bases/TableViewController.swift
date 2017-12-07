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
    
    let networkErrorDisplayer = NetworkErrorDisplayer()
    
    func displayNetworkUpdateError(error: Error) {
        networkErrorDisplayer.displayError(on: self)
    }
    
    func hideNetworkUpdateError() {
        networkErrorDisplayer.hideError(on: self)
    }
        
}
