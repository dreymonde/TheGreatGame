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
    internal let uploadConsistencyKeeper: UploadConsistencyKeeper<FlagSet<Flag>>
    
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
                  uploadConsistencyKeeper: UploadConsistencyKeeper<FlagSet<Flag>>,
                  shouldCheckUploadConsistency: Subscribe<Void>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper = uploadConsistencyKeeper
        
        start(shouldCheckUploadConsistency: shouldCheckUploadConsistency)
    }
        
    internal func start(shouldCheckUploadConsistency: Subscribe<Void>) {
        shouldCheckUploadConsistency.subscribe(uploadConsistencyKeeper, with: UploadConsistencyKeeper.check)
    }
    
    public var didUploadFlags: Subscribe<FlagSet<Flag>> {
        return uploader.didUploadFavorites.proxy.map({ $0.favorites })
    }
    
    public func subscribe() {
        self.uploadConsistencyKeeper.subscribeTo(didUpload: uploader.didUploadFavorites.proxy.map({ $0.favorites }))
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
                                consistencyKeepersStorage: Storage<Filename, Data>,
                                upload: WriteOnlyStorage<Void, Data>) {
            let favs = registry.flags.defaulting(to: FlagSet<Flag>([]))
            let uploader = FlagsUploader<Flag>(pusher: FlagsUploader<Flag>.adapt(pusher: upload),
                                                     getNotificationsToken: tokens.getNotification,
                                                     getDeviceIdentifier: { UIDevice.current.identifierForVendor })
            let keeper = Flags.makeKeeper(diskCache: consistencyKeepersStorage, flags: favs, uploader: uploader)
            self.init(registry: registry,
                      uploader: uploader,
                      uploadConsistencyKeeper: keeper,
                      shouldCheckUploadConsistency: shouldCheckUploadConsistency)
        }
        
    }
    
#endif

extension Flags {
    
    fileprivate static func makeKeeper(diskCache: Storage<Filename, Data>,
                                       flags: Retrieve<FlagSet<Flag>>,
                                       uploader: FlagsUploader<Flag>) -> UploadConsistencyKeeper<FlagSet<Flag>> {
        let name = "keeper-notifications-\(String(reflecting: IDType.self))"
        let last = diskCache
            .mapJSONDictionary()
            .mapFlagSet(of: Flag.self)
            .singleKey(Filename(rawValue: name))
            .defaulting(to: FlagSet([]))
        return UploadConsistencyKeeper<FlagSet<Flag>>(latest: flags, internalStorage: last, name: name, reupload: { upload in
            uploader.uploadFavorites(upload)
        })
    }
    
}
