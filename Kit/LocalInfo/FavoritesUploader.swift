//
//  FavoriteTeamsUploader.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import Shallows

internal final class FavoritesUploader<IDType : IDProtocol> where IDType.RawValue == Int {
    
    let getNotificationsToken: Retrieve<PushToken>
    let getDeviceIdentifier: () -> UUID?
    
    init(pusher: Cache<Void, FavoritesUpload<IDType>>,
         getNotificationsToken: Retrieve<PushToken>,
         getDeviceIdentifier: @escaping () -> UUID?) {
        self.pusher = pusher
        self.getNotificationsToken = getNotificationsToken
        self.getDeviceIdentifier = getDeviceIdentifier
    }
    
    internal static func adapt(pusher: Cache<Void, Data>) -> Cache<Void, FavoritesUpload<IDType>> {
        return pusher
            .mapJSONDictionary()
            .mapMappable()
    }
    
    let pusher: Cache<Void, FavoritesUpload<IDType>>
    
    internal func declare(didUpdateFavorites: Subscribe<Set<IDType>>) {
        didUpdateFavorites.subscribe(self, with: FavoritesUploader.uploadFavorites)
    }
    
    internal func uploadFavorites(_ update: Set<IDType>) {
        printWithContext()
        uploadFavorites(update, usingTokenProvider: getNotificationsToken)
    }
    
    private func uploadFavorites(_ favorites: Set<IDType>, usingTokenProvider provider: Retrieve<PushToken>) {
        guard let deviceIdentifier = getDeviceIdentifier() else {
            fault("No device UUID")
            return
        }
        provider.retrieve { (result) in
            if let token = result.value {
                let upload = FavoritesUpload(deviceIdentifier: deviceIdentifier,
                                             token: token,
                                             favorites: favorites)
                self.pusher.set(upload, completion: { (result) in
                    if let error = result.error {
                        printWithContext("Failed to write favorites \(favorites). Error: \(error)")
                    } else {
                        self.didUploadFavorites.publish(upload)
                    }
                })
            } else {
                printWithContext("No token for notifications")
            }
        }
    }
    
    let didUploadFavorites = Publisher<FavoritesUpload<IDType>>(label: "FavoritesUploader.didUploadFavorites")
    
}

internal struct FavoritesUpload<IDType : IDProtocol> {
    
    let deviceIdentifier: UUID
    let token: PushToken
    let favorites: Set<IDType>
    
}

extension FavoritesUpload : Mappable {
    
    enum MapError : Error {
        case outOnly
    }
    
    enum MappingKeys : String, IndexPathElement {
        case token, favorites, device_identifier
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        throw MapError.outOnly
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.deviceIdentifier.uuidString, to: .device_identifier)
        try mapper.map(self.token.string, to: .token)
        try mapper.map(Array(self.favorites), to: .favorites)
    }
    
}
