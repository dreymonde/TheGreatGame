//
//  NotificationsReceiver.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 12.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UserNotifications
import Alba

internal final class NotificationsReceiver : NSObject, UNUserNotificationCenterDelegate {
    
    let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let notification = try? PushNotification(response.notification.request.content) else {
            print(response.notification.request.content.userInfo)
            fault("Cannot initialize PushNotification")
            return
        }
        guard let action = NotificationAction(actionIdentifier: response.actionIdentifier) else {
            fault("Unknown action identifier")
            return
        }
        let nativeResponse = NotificationResponse(action: action, notification: notification)
        didReceiveNotificationResponse.publish(nativeResponse)
        completionHandler()
    }
    
    let didReceiveNotificationResponse = Publisher<NotificationResponse>(label: "NotificationsReceiver.didRecieveNotificationResponse")
    
}

