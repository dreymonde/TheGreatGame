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
    
    public let didReceiveNotificationResponse: Publisher<NotificationResponse>
    
    public init<Application : CanAuthorizeForRemoteNotifications>(application: Application) {
        self.authorizer = NotificationAuthorizer(application: application)
        self.receiver = NotificationsReceiver()
        self.didReceiveNotificationResponse = receiver.didReceiveNotificationResponse
        self.start()
    }
    
    internal func start() {
        authorizer.start()
    }
    
}
