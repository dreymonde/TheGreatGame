//
//  ViewController.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit

class ViewController : UIViewController {
    
    deinit {
        printWithContext("Deinit \(self)")
    }
    
}

extension UIViewController {
    
    func presentText(_ text: String) {
        let alert = UIAlertController(title: nil,
                                      message: "Marking a team as favorite enables push notifications. It also gives priority for the games of this team for Today widget and Apple Watch complication.",
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK",
                               style: .default,
                               handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
        
}
