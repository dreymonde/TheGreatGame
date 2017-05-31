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

public final class AppleWatch {
    
    internal let session: WatchSessionManager
    internal let pushKitReceiver: PushKitReceiver
    internal let pusher: ComplicationPusher
    
    public init?() {
        guard let session = WatchSessionManager.init(0) else {
            return nil
        }
        self.session = session
        self.pushKitReceiver = PushKitReceiver()
        self.pusher = ComplicationPusher()
    }
    
    public func declare(didUpdateFavorites: Subscribe<Set<Team.ID>>) {
        pusher.declare(didReceiveIncomingPush: pushKitReceiver.didReceiveIncomingPush.proxy)
        session.declare(complicationMatchUpdate: pusher.didReceiveComplicationMatchUpdate.proxy)
        session.feed(packages: didUpdateFavorites.map(FavoritesPackage.init))
    }
    
}

public final class WatchSessionManager : NSObject, WCSessionDelegate {
    
    let session = WCSession.default()
    
    var activeSession: ActiveWatchSession? = nil
    
    public init?(_ flag: Int8) {
        guard WCSession.isSupported() else {
            return nil
        }
        super.init()
        session.delegate = self
        session.activate()
    }
    
    public func send(_ package: Package) {
        guard session.activationState == .activated else {
            printWithContext("Session is not active")
            return
        }
        do {
            let rawPackage = try package.map() as [String : Any]
            session.transferUserInfo(rawPackage)
            printWithContext("Sending package \(package.kind)...")
            didSendPackage.publish(package)
        } catch {
            didFailToSendPackage.publish(error)
        }
    }
    
    public func sendComplicationUserInfo(_ package: Package) {
        do {
            let rawPackage = try package.map()
            session.transferCurrentComplicationUserInfo(rawPackage)
            printWithContext("Updating complication user info...")
            didSendPackage.publish(package)
        } catch {
            didFailToSendPackage.publish(error)
        }
    }
    
    public func declare(complicationMatchUpdate: Subscribe<Match.Full>) {
        complicationMatchUpdate.flatMap({ try? $0.pack() })
            .subscribe(self, with: WatchSessionManager.sendComplicationUserInfo)
    }
    
    public func feed<Pack : AppleWatchPackable>(packages: Subscribe<Pack>) {
        packages.flatMap({ try? $0.pack() })
            .subscribe(self, with: WatchSessionManager.send)
    }
    
    let didSendPackage = Publisher<Package>(label: "WatchSessionManager.didSendPackage")
    let didFailToSendPackage = Publisher<Error>(label: "WatchSessionManager.didFailToSendPackage")
    
}

extension WatchSessionManager {
    
    public func sessionDidDeactivate(_ session: WCSession) {
        printWithContext()
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        printWithContext()
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        printWithContext()
        if activationState == .activated {
            if let newSession = ActiveWatchSession(session: session) {
                self.activeSession = newSession
                newSession.start()
            }
        }
    }
    
}

internal final class ActiveWatchSession {
    
    let session: WCSession
    let directoryURL: URL
    let directoryURLCache: RawFileSystemCache
    let watchInfo: Cache<Void, AppleWatchInfo>
    
    init?(session: WCSession) {
        guard session.activationState == .activated,
            let url = session.watchDirectoryURL else {
                return nil
        }
        self.session = session
        self.directoryURL = url
        self.directoryURLCache = RawFileSystemCache(directoryURL: url, qos: .background)
        let mapped = directoryURLCache
            .mapPlistDictionary()
            .mapMappable(of: AppleWatchInfo.self)
            .singleKey(.init("watch-info.plist"))
            .defaulting(to: .blank)
        self.watchInfo = SingleElementMemoryCache().combined(with: mapped)
    }
    
    func start() {
        act()
    }
    
    private func act() {
        watchInfo.retrieve { (result) in
            let info = result.asOptional!
            if info.wasPairedBefore {
                print("Was paired before")
            } else {
                print("First pair")
                self.watchInfo.update({ $0.wasPairedBefore = true })
            }
        }
    }
    
}

internal struct AppleWatchInfo {
    
    var wasPairedBefore: Bool
    var sentInitialFavorites: Bool
    
    init(wasPairedBefore: Bool, sentInitialFavorites: Bool) {
        self.wasPairedBefore = wasPairedBefore
        self.sentInitialFavorites = sentInitialFavorites
    }
    
    static var blank: AppleWatchInfo {
        return AppleWatchInfo(wasPairedBefore: false, sentInitialFavorites: false)
    }
    
}

extension AppleWatchInfo : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case was_paired_before, sent_initial_favorites
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.wasPairedBefore = try mapper.map(from: .was_paired_before)
        self.sentInitialFavorites = try mapper.map(from: .sent_initial_favorites)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.wasPairedBefore, to: .was_paired_before)
        try mapper.map(self.sentInitialFavorites, to: .sent_initial_favorites)
    }
    
}
