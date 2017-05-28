//
//  Refreshing.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit

protocol Refreshing : class {
    
    var refreshControl: UIRefreshControl? { get }
    
}

extension Refreshing {
    
    func make() -> NetworkActivityIndicatorManager {
        return NetworkActivityIndicatorManager(show: { [weak self] in
            self?.refreshControl?.beginRefreshing()
            }, hide: { [weak self] in
                self?.refreshControl?.endRefreshing()
        })
    }
    
}
