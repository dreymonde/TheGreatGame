//
//  ComplicationPusher.swift
//  TheGreatGame
//
//  Created by Олег on 31.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import PushKit
import UserNotifications

public final class ComplicationPusher {
    
    public let didReceiveComplicationMatchUpdate = Publisher<Match.Full>(label: "ComplicationPusher.didReceiveComplicationMatchUpdate")
    
    public func declare(didReceiveIncomingPush: Subscribe<PKPushPayload>) {
        didReceiveIncomingPush
            .flatMap({ $0.dictionaryPayload as? [String : Any] })
            .flatMap({ try? PushNotification(from: $0) })
            .flatMap({ try? Match.Full(from: $0.content) })
            .redirect(to: didReceiveComplicationMatchUpdate)
    }
    
}

public final class PushKitReceiver : NSObject, PKPushRegistryDelegate {
    
    public let registry: PKPushRegistry
    
    public override init() {
        self.registry = PKPushRegistry(queue: nil)
        super.init()
        registry <- {
            $0.delegate = self
            $0.desiredPushTypes = [.complication]
        }
    }
    
    public let didRegisterWithToken = Publisher<PushToken>(label: "PushKitReceiver.didRegisterWithToken")
    public let didReceiveIncomingPush = Publisher<PKPushPayload>(label: "PushKitReceiver.didReceiveIncomingPush")
    
}

extension PushKitReceiver {
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        let token = PushToken(credentials.token)
        didRegisterWithToken.publish(token)
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        
        let content = UNMutableNotificationContent() <- {
            $0.title = "Update"
            $0.body = "I got some news"
            $0.sound = UNNotificationSound.default()
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { (error) in
            print("Add notif:", error as Any)
        }
        didReceiveIncomingPush.publish(payload)
        dump(payload.dictionaryPayload)
    }
    
}
