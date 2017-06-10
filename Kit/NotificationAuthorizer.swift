//
//  NotificationAuthorizer.swift
//  TheGreatGame
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import UserNotifications
import Alba

internal final class NotificationAuthorizer {
    
    let center = UNUserNotificationCenter.current()
    let registerForRemote: () -> ()
    
    internal init(registerForRemote: @escaping () -> ()) {
        self.registerForRemote = registerForRemote
    }
    
    internal convenience init<Application : CanAuthorizeForRemoteNotifications>(application: Application) {
        self.init(registerForRemote: application.registerForRemoteNotifications)
    }
    
    internal func authorize() {
        center.requestAuthorization(options: [.alert, .sound]) { (authorized, error) in
            if let error = error {
                self.didFailToAuthorizeForNotifications.publish(error)
                return
            }
            if authorized {
                self.registerForRemote()
                self.didAuthorize.publish()
            }
        }
    }
    
    internal let didAuthorize = Publisher<Void>(label: "NotificationAuthorizer.didAuthorize")
    internal let didFailToAuthorizeForNotifications = Publisher<Error>(label: "NotificationAuthorizer.didFailToAuthorizeForNotifications")
    
}

public protocol CanAuthorizeForRemoteNotifications {
    
    func registerForRemoteNotifications()
    
}

#if os(iOS)
    
    extension UIApplication : CanAuthorizeForRemoteNotifications { }
    
#endif

