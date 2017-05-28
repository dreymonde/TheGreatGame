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
    
    var watchInfo: Cache<Void, AppleWatchInfo>? = nil
    
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
        if activationState == .activated, let directory = session.watchDirectoryURL {
            let fs = RawFileSystemCache(directoryURL: directory)
                .mapPlistDictionary()
                .mapMappable(of: AppleWatchInfo.self)
                .singleKey(.init("watch-info.plist"))
                .defaulting(to: .blank)
            let watchInfo = SingleElementMemoryCache().combined(with: fs)
            self.watchInfo = watchInfo
            act(on: watchInfo)
        }
    }
    
    func act(on cache: Cache<Void, AppleWatchInfo>) {
        cache.retrieve { (result) in
            if let info = result.asOptional {
                if info.wasPairedBefore {
                    print("Not first pair")
                } else {
                    print("First pair")
                    cache.update({ $0.wasPairedBefore = true })
                }
            }
        }
    }
    
}

internal struct AppleWatchInfo {
    
    var wasPairedBefore: Bool
    
    init(wasPairedBefore: Bool) {
        self.wasPairedBefore = wasPairedBefore
    }
    
    static var blank: AppleWatchInfo {
        return AppleWatchInfo(wasPairedBefore: false)
    }
    
}

extension AppleWatchInfo : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case was_paired_before
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.wasPairedBefore = try mapper.map(from: .was_paired_before)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.wasPairedBefore, to: .was_paired_before)
    }
    
}
