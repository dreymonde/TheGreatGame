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
            .flatMap({ PushNotification<Match.Full>(userInfo: $0.dictionaryPayload)?.content })
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
        didReceiveIncomingPush.publish(payload)
        dump(payload.dictionaryPayload)
    }
    
}
