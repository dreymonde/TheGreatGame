//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import WatchKit
import Foundation
import Alba
import TheGreatKit

class InterfaceController: WKInterfaceController {

    @IBOutlet var favoritesLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WatchExtension.main.updates.subscribe(self, with: InterfaceController.updateFavorites)
        // Configure interface objects here.
    }
    
    func updateFavorites(favorites: Set<Team.ID>) {
        self.favoritesLabel.setText(String.init(describing: favorites))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
