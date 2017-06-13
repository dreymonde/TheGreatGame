//
//  DeviceTokens.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import Shallows

public final class DeviceTokens {
    
    var notifications: ThreadSafe<PushToken?> = ThreadSafe(nil)
    var complication: ThreadSafe<PushToken?> = ThreadSafe(nil)
    
    public init() { }
    
    public func declare(notifications: Subscribe<PushToken>, complication: Subscribe<PushToken>) {
        notifications.subscribe(self, with: DeviceTokens.updateNotificationsToken)
        complication.subscribe(self, with: DeviceTokens.updateComplicationToken)
    }
    
    func updateNotificationsToken(_ token: PushToken) {
        self.notifications.write(token)
    }
    
    func updateComplicationToken(_ token: PushToken) {
        self.complication.write(token)
    }
    
}
