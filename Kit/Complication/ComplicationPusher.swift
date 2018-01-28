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
    
    public static let adapter: AlbaAdapter<PKPushPayload, Match.Full> = { proxy in
        return proxy
            .flatMap({ try? PushNotification(userInfo: $0.dictionaryPayload).extract(Match.Full.self) })
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
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let token = PushToken(credentials.token)
        didRegisterWithToken.publish(token)
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        didReceiveIncomingPush.publish(payload)
    }
    
}
