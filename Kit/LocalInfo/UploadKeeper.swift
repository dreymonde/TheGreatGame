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

internal final class UploadConsistencyKeeper<Upload : Equatable> {
    
    let favorites: ReadOnlyCache<Void, Upload>
    let lastUploaded: Cache<Void, Upload>
    
    init(favorites: ReadOnlyCache<Void, Upload>, lastUploaded: Cache<Void, Upload>) {
        self.favorites = favorites
        self.lastUploaded = lastUploaded
    }
    
    func declare(didUploadFavorites: Subscribe<Upload>) {
        didUploadFavorites.subscribe(self, with: UploadConsistencyKeeper.didUploadFavorites)
    }
    
    func didUploadFavorites(_ upload: Upload) {
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
    
    let shouldUploadFavorites = Publisher<Upload>(label: "FavoritesUploadKeeper.shouldUploadFavorites")
    
}

extension UploadConsistencyKeeper where Upload == Set<Team.ID> {
    
    convenience init(favorites: ReadOnlyCache<Void, Set<Team.ID>>, diskCache: Cache<String, Data>) {
        let last: Cache<Void, Set<Team.ID>> = diskCache
            .mapJSONDictionary()
            .mapBoxedSet()
            .singleKey("last-uploaded-favorites-teams")
            .defaulting(to: [])
        self.init(favorites: favorites, lastUploaded: last)
    }
    
}
