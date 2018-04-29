//
//  FavoriteTeams.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public final class Flags<Flag : FlagDescriptor> {
    
    public typealias IDType = Flag.IDType
    
    public let registry: FlagsRegistry<Flag>
    internal let uploader: FlagsUploader<Flag>
    internal let serverConsistencyChecker: ConsistencyChecker<FlagSet<Flag>>
    
    public struct Change {
        public var id: IDType
        public var isPresent: Bool
        
        public init(id: IDType, isPresent: Bool) {
            self.id = id
            self.isPresent = isPresent
        }
        
        public var reversed: Change {
            return Change(id: id, isPresent: !isPresent)
        }
    }
    
    internal init(registry: FlagsRegistry<Flag>,
                  uploader: FlagsUploader<Flag>,
                  serverMirror: Storage<Void, Flag.Set>,
                  shouldCheckUploadConsistency: Subscribe<Void>) {
        self.registry = registry
        self.uploader = uploader
        let checker = ConsistencyChecker<Flag.Set>(truth: registry.flags,
                                                   destinationMirror: serverMirror,
                                                   name: Flag.filename.rawValue)
        self.serverConsistencyChecker = checker
    }
    
    public var didUploadFlags: Subscribe<FlagSet<Flag>> {
        return uploader.didUploadFlags
    }
    
    public func subscribeTo(shouldCheckUploadConsistency: Subscribe<Void>) {
        
        serverConsistencyChecker.upload.delegate(to: uploader) { (uploader, flags) in
            uploader.uploadFavorites(flags)
        }
        
        shouldCheckUploadConsistency.subscribe(serverConsistencyChecker, with: ConsistencyChecker.check)
        self.serverConsistencyChecker.subcribeTo(didUpload: didUploadFlags)
        registry.unitedDidUpdate.proxy.flatSubscribe(uploader) { (uploader, update) in
            uploader.uploadFavorites(update.flags)
        }
    }
    
}

public func unsubscribe(fromMatchWith matchID: Match.ID, registry: FlagsRegistry<UnsubscribedMatches>, flagsDidUpload: Subscribe<FlagSet<UnsubscribedMatches>>, completion: @escaping () -> ()) {
    printWithContext("Unsubscribing from \(matchID)")
    
    let expectedFlags = registry.flagsAfter(updatingPresenceOf: matchID, isPresent: true)
    flagsDidUpload.listen { (uploadedFlags, stop) in
        print("UPLD", uploadedFlags)
        if uploadedFlags == expectedFlags {
            printWithContext("Uploaded \(matchID)")
            stop()
            completion()
        }
    }
    
    registry.updatePresence(id: matchID, isPresent: true)
}

#if os(iOS)
    
    extension Flags {
        
        public convenience init(registry: FlagsRegistry<Flag>,
                                tokens: DeviceTokens,
                                shouldCheckUploadConsistency: Subscribe<Void>,
                                upload: WriteOnlyStorage<Void, Data>) {
            let uploader = FlagsUploader<Flag>(pusher: FlagsUploader<Flag>.adapt(pusher: upload),
                                               getNotificationsToken: tokens.getNotification,
                                               getDeviceIdentifier: { UIDevice.current.identifierForVendor })
            let mirror = destinationMirror(descriptor: Flag.self)
            self.init(registry: registry, uploader: uploader, serverMirror: mirror, shouldCheckUploadConsistency: shouldCheckUploadConsistency)
        }
        
    }
    
#endif
