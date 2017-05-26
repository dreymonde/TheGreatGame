//
//  AppleWatch.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import WatchConnectivity
import Alba
import Shallows

public final class AppleWatch : NSObject, WCSessionDelegate {
    
    let session = WCSession.default()
    
    public override init() {
        super.init()
        session.delegate = self
        session.activate()
    }
    
    public func send(_ package: Package) {
        do {
            let rawPackage = try package.map() as [String : Any]
            session.transferUserInfo(rawPackage)
        } catch {
            didFailToSendPackage.publish(error)
        }
    }
    
    public func feed<Pack : AppleWatchPackable>(packages: Subscribe<Pack>) {
        packages.flatMap({ try? $0.pack() })
            .subscribe(self, with: AppleWatch.send)
    }
    
    let didFailToSendPackage = Publisher<Error>(label: "AppleWatch.didFailToSendPackage")
    
}

extension AppleWatch {
    
    public func sessionDidDeactivate(_ session: WCSession) {
        printWithContext()
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        printWithContext()
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        printWithContext()
    }
    
}
