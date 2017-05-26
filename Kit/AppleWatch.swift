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

public final class FavoritesToAppleWatch {
    
    public let watch: AppleWatch
    
    public init(watch: AppleWatch) {
        self.watch = watch
    }
    
    public func declare(favoritesDidUpdate: Subscribe<Set<Team.ID>>) {
        favoritesDidUpdate.subscribe(self, with: FavoritesToAppleWatch.favoritesDidUpdate)
    }
    
    fileprivate func favoritesDidUpdate(_ favorites: Set<Team.ID>) {
        watch.send(try! FavoritesPackage.init(favs: favorites).pack())
    }
    
}
