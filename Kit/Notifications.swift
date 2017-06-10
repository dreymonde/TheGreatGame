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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let notification = PushNotification(response.notification.request.content) else {
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

public struct NotificationResponse {
    
    public let action: NotificationAction
    public let notification: PushNotification
    
}

public enum NotificationAction {
    
    case open
    
    public init?(actionIdentifier: String) {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            self = .open
        default:
            return nil
        }
    }
    
}

extension PushNotification {
    
    public init?(_ content: UNNotificationContent) {
        guard let payload = content.userInfo as? [String : Any] else {
            return nil
        }
        do {
            try self.init(from: payload)
        } catch {
            print(error)
            return nil
        }
    }
    
}
