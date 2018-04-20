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

public final class Flags<Descriptor : RegistryDescriptor> {
    
    public typealias IDType = Descriptor.IDType
    
    public let registry: FlagsRegistry<Descriptor>
    internal let uploader: FlagsUploader<Descriptor>
    internal let uploadConsistencyKeeper: UploadConsistencyKeeper<FlagsSet<Descriptor>>
    
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
    
    internal init(registry: FlagsRegistry<Descriptor>,
                  uploader: FlagsUploader<Descriptor>,
                  uploadConsistencyKeeper: UploadConsistencyKeeper<FlagsSet<Descriptor>>,
                  shouldCheckUploadConsistency: Subscribe<Void>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper = uploadConsistencyKeeper
        
        start(shouldCheckUploadConsistency: shouldCheckUploadConsistency)
    }
        
    internal func start(shouldCheckUploadConsistency: Subscribe<Void>) {
        shouldCheckUploadConsistency.subscribe(uploadConsistencyKeeper, with: UploadConsistencyKeeper.check)
    }
    
    public func subscribe() {
        self.uploadConsistencyKeeper.subscribeTo(didUpload: uploader.didUploadFavorites.proxy.map({ $0.favorites }))
        registry.unitedDidUpdate.proxy.flatSubscribe(uploader) { (uploader, update) in
            uploader.uploadFavorites(update.flags)
        }
    }
    
}

#if os(iOS)
    
    extension Flags {
        
        public convenience init(registry: FlagsRegistry<Descriptor>,
                                tokens: DeviceTokens,
                                shouldCheckUploadConsistency: Subscribe<Void>,
                                consistencyKeepersStorage: Storage<Filename, Data>,
                                upload: WriteOnlyStorage<Void, Data>) {
            let favs = registry.flags.defaulting(to: FlagsSet<Descriptor>([]))
            let uploader = FlagsUploader<Descriptor>(pusher: FlagsUploader<Descriptor>.adapt(pusher: upload),
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
                                       flags: Retrieve<FlagsSet<Descriptor>>,
                                       uploader: FlagsUploader<Descriptor>) -> UploadConsistencyKeeper<FlagsSet<Descriptor>> {
        let name = "keeper-notifications-\(String(reflecting: IDType.self))"
        let last = diskCache
            .mapJSONDictionary()
            .mapFlagsSet(of: Descriptor.self)
            .singleKey(Filename(rawValue: name))
            .defaulting(to: FlagsSet([]))
        return UploadConsistencyKeeper<FlagsSet<Descriptor>>(latest: flags, internalStorage: last, name: name, reupload: { upload in
            uploader.uploadFavorites(upload)
        })
    }
    
}
