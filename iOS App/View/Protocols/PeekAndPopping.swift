//
//  PeekAndPopping.swift
//  TheGreatGame
//
//  Created by Олег on 16.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

@objc protocol Showing : UIViewControllerPreviewingDelegate {
    
    func viewController(for indexPath: IndexPath) -> UIViewController?
    
}

extension Showing where Self : UITableViewController {
    
    func viewController(for location: CGPoint, previewingContext: UIViewControllerPreviewing) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        guard let vc = viewController(for: indexPath) else {
            return nil
        }
        let cellRect = tableView.rectForRow(at: indexPath)
        let sourceRect = previewingContext.sourceView.convert(cellRect, from: tableView)
        previewingContext.sourceRect = sourceRect
        return vc
    }
        
    func registerForPeekAndPop() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    func showViewController(for indexPath: IndexPath) {
        if let vc = viewController(for: indexPath) {
            show(vc, sender: self)
        }
    }
    
}

