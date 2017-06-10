//
//  Notifications.swift
//  TheGreatGame
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import UserNotifications

public final class Notifications {
    
    let authorizer: NotificationAuthorizer
    let receiver: NotificationsReceiver
    
    public init<Application : CanAuthorizeForRemoteNotifications>(application: Application) {
        self.authorizer = NotificationAuthorizer(application: application)
        self.receiver = NotificationsReceiver()
        self.start()
    }
    
    internal func start() {
        authorizer.authorize()
    }
    
}

internal final class NotificationsReceiver : NSObject, UNUserNotificationCenterDelegate {
    
    let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
}
