//
//  Phone.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import WatchConnectivity
import Alba

public final class Phone : NSObject, WCSessionDelegate {
    
    let session = WCSession.default()
    
    public override init() {
        super.init()
        session.delegate = self
        session.activate()
    }
    
    public let didReceivePackage = Publisher<Package>(label: "Phone.didReceivePackage")
    
}

extension Phone {
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        do {
            let package = try Package(from: userInfo)
            didReceivePackage.publish(package)
        } catch {
            fault(error)
        }
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        printWithContext()
    }
    
}
