//
//  UploadKeeper.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

internal final class FavoritesUploadKeeper<IDType : IDProtocol> where IDType.RawValue == Int {
    
    let favorites: ReadOnlyCache<Void, Set<IDType>>
    let lastUploaded: Cache<Void, Set<IDType>>
    
    init(favorites: ReadOnlyCache<Void, Set<IDType>>, lastUploaded: Cache<Void, Set<IDType>>) {
        self.favorites = favorites
        self.lastUploaded = lastUploaded
    }
    
    convenience init(favorites: ReadOnlyCache<Void, Set<IDType>>, diskCache: Cache<String, Data>) {
        let last: Cache<Void, Set<IDType>> = diskCache
            .mapJSONDictionary()
            .mapMappable(of: FavoritesBox<IDType>.self)
            .singleKey("last-uploaded-favorites")
            .mapValues(transformIn: { Set($0.all) },
                       transformOut: { FavoritesBox(all: Array($0)) })
            .defaulting(to: [])
        self.init(favorites: favorites, lastUploaded: last)
    }
    
    func declare(didUploadFavorites: Subscribe<Set<IDType>>) {
        didUploadFavorites.subscribe(self, with: FavoritesUploadKeeper.didUploadFavorites)
    }
    
    func didUploadFavorites(_ upload: Set<IDType>) {
        lastUploaded.set(upload)
    }
    
    func check() {
        printWithContext("Checking if last update was properly uploaded")
        zip(favorites, lastUploaded.asReadOnlyCache()).retrieve { (result) in
            guard let value = result.value else {
                fault("Both caches should be defaulted")
                return
            }
            let favors = value.0
            let lasts = value.1
            if lasts != favors {
                self.shouldUploadFavorites.publish(favors)
            } else {
                printWithContext("It was")
            }
        }
    }
    
    let shouldUploadFavorites = Publisher<Set<IDType>>(label: "FavoritesUploadKeeper.shouldUploadFavorites")
    
}
