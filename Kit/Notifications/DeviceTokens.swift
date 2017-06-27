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
    
    public private(set) var getNotification: Retrieve<PushToken>!
    public private(set) var getComplication: Retrieve<PushToken>!
    
    public init() {
        self.getNotification = Retrieve<PushToken>(cacheName: "retrieve-notif", retrieve: { (_, completion) in
            do {
                let val = try self.notifications.read().unwrap()
                completion(.success(val))
            } catch {
                completion(.failure(error))
            }
        })
        self.getComplication = Retrieve<PushToken>(cacheName: "retrieve-compl", retrieve: { (_, completion) in
            do {
                let val = try self.complication.read().unwrap()
                completion(.success(val))
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    public func declare(notifications: Subscribe<PushToken>, complication: Subscribe<PushToken>) {
        notifications.subscribe(self, with: DeviceTokens.updateNotificationsToken)
        complication.subscribe(self, with: DeviceTokens.updateComplicationToken)
    }
    
    public let didUpdateNotificationsToken = Publisher<PushToken>(label: "DeviceTokens.didUpdateNotificationsToken")
    public let didUpdateComplicationToken = Publisher<PushToken>(label: "DeviceTokens.didUpdateComplicationToken")
    
    func updateNotificationsToken(_ token: PushToken) {
        self.notifications.write(token)
        didUpdateNotificationsToken.publish(token)
    }
    
    func updateComplicationToken(_ token: PushToken) {
        self.complication.write(token)
        didUpdateComplicationToken.publish(token)
    }
    
}
