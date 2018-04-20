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

internal final class FlagsUploader<Descriptor : RegistryDescriptor> {
    
    typealias IDType = Descriptor.IDType
    
    let getNotificationsToken: Retrieve<PushToken>
    let getDeviceIdentifier: () -> UUID?
    
    init(pusher: WriteOnlyStorage<Void, FavoritesUpload<Descriptor>>,
         getNotificationsToken: Retrieve<PushToken>,
         getDeviceIdentifier: @escaping () -> UUID?) {
        self.pusher = pusher
        self.getNotificationsToken = getNotificationsToken
        self.getDeviceIdentifier = getDeviceIdentifier
    }
    
    internal static func adapt(pusher: WriteOnlyStorage<Void, Data>) -> WriteOnlyStorage<Void, FavoritesUpload<Descriptor>> {
        return pusher
            .mapJSONDictionary()
            .mapMappable()
    }
    
    let pusher: WriteOnlyStorage<Void, FavoritesUpload<Descriptor>>
    
    func uploadFavorites(_ update: FlagsSet<Descriptor>) {
        printWithContext()
        uploadFavorites(update, usingTokenProvider: getNotificationsToken)
    }
    
    private func uploadFavorites(_ favorites: FlagsSet<Descriptor>, usingTokenProvider provider: Retrieve<PushToken>) {
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
    
    let didUploadFavorites = Publisher<FavoritesUpload<Descriptor>>(label: "FlagsUploader<\(Descriptor.self)>.didUploadFavorites")
    
}

internal struct FavoritesUpload<Descriptor : RegistryDescriptor> {
    
    let deviceIdentifier: UUID
    let token: PushToken
    let favorites: FlagsSet<Descriptor>
    
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
        try mapper.map(Array(self.favorites.set), to: .favorites)
    }
    
}
