//
//  NotificationResponse.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 12.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import UserNotifications

public struct NotificationResponse {
    
    public let action: NotificationAction
    public let notification: PushNotification
    
}

public enum NotificationAction {
    
    case open
    case unsubscribe
    
    public init?(actionIdentifier: String) {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            self = .open
        case NotificationAction.unsubscribeIdentifier:
            self = .unsubscribe
        default:
            return nil
        }
    }
    
    static let unsubscribeIdentifier = "unsubscribe"
    
}

extension PushNotification {
    
    public init(_ content: UNNotificationContent) throws {
        try self.init(userInfo: content.userInfo)
    }
    
}
