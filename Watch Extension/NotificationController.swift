//
//  NotificationController.swift
//  Watch Extension
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import WatchKit
import Foundation
import UserNotifications
import TheGreatKit

class NotificationController: WKUserNotificationInterfaceController {

    @IBOutlet var testLabel: WKInterfaceLabel!
    
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
        // This method is called when a notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        guard let match = try? PushNotification(notification.request.content).extract(Match.Full.self) else {
            fault("Not a match push notification")
            return
        }
        self.testLabel.setText("\(match.home.name) \(match.score?.string ?? "VS") \(match.away.name)")
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.custom)
    }
}
