//
//  Caches.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Avenues
import Shallows
import UIKit

extension CacheProtocol where Value == Data {
    
    public func mapImage() -> Cache<Key, UIImage> {
        return mapValues(transformIn: { try UIImage.init(data: $0, scale: 2.0).unwrap() },
                         transformOut: throwing(UIImagePNGRepresentation))
    }
    
}

public final class ImageFetch {
    
    internal var caches: [Int : Storage<URL, UIImage>] = [:]
    
    fileprivate let imageFetchingSession = URLSession(configuration: .default)
    fileprivate let diskCache: Cache<URL, UIImage>
    
    public init(diskCache: Cache<URL, UIImage>) {
        self.diskCache = diskCache
    }
    
    public convenience init(shouldCacheToDisk: Bool) {
        self.init(diskCache: shouldCacheToDisk ? DiskCaching.inCachesDirectorySharedContainer().cache : .empty())
    }
    
    public func imageCache(forSize side: CGFloat) -> Storage<URL, UIImage> {
        let intside = Int(side)
        if let existing = caches[intside] {
            return existing
        } else {
            let new: Storage<URL, UIImage> = ImageNSCache()
                .mapValue(inTransform: { assert(max($0.size.width, $0.size.height) == side); return $0 },
                          outTransform: { assert(max($0.size.width, $0.size.height) == side); return $0 })
            caches[intside] = new
            return new
        }
    }
    
    public func makeAvenue(forImageSize imageSize: CGSize) -> Avenue<URL, URL, UIImage> {
        let fullSizedLane: Processor<URL, UIImage> = URLSessionProcessor(session: imageFetchingSession)
            .mapImage()
            .caching(to: diskCache)
        let lane = fullSizedLane.mapValue({ $0.resized(toFit: imageSize) })
        let storage = imageCache(forSize: imageSize.width)
        return Avenue(storage: storage, processor: lane)
    }
    
    public func makeDoubleCachedAvenue(forImageSize imageSize: CGSize) -> Avenue<URL, URL, UIImage> {
        let lane: Processor<URL, UIImage> = URLSessionProcessor(session: imageFetchingSession)
            .mapImage()
            .caching(to: diskCache)
            .mapValue({ $0.resized(toFit: imageSize) })
            .caching(to: diskCache.mapKeys({ $0.appendingPathComponent("-\(imageSize.width)") }))
        let storage = imageCache(forSize: imageSize.width)
        return Avenue(storage: storage, processor: lane)
    }
    
}

public enum EmptyCacheError : Error {
    case cacheIsAlwaysEmpty
}

extension ReadOnlyCache {
    
    public static func empty() -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache(cacheName: "empty", retrieve: { (_, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        })
    }
    
}

extension Cache {
    
    public static func empty() -> Cache<Key, Value> {
        return Cache(cacheName: "empty", retrieve: { (_, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        }, set: { (_, _, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        })
    }
    
}

extension ImageFetch {
    
    internal final class DiskCaching {
        
        private let rawImagesDiskCache: FileSystemCache
        internal let cache: Cache<URL, UIImage>
        
        internal init(rawImagesDiskCache: FileSystemCache) {
            self.rawImagesDiskCache = rawImagesDiskCache
            self.cache = rawImagesDiskCache
                .mapImage()
                .mapKeys({ $0.absoluteString })
        }
        
        internal static func inCachesDirectoryOwnContainer() -> DiskCaching {
            return DiskCaching(rawImagesDiskCache: .inDirectory(.cachesDirectory, appending: "badges"))
        }
        
        internal static func inCachesDirectorySharedContainer() -> DiskCaching {
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.the-great-game.the-great-group")?.appendingPathComponent("Library/Caches/badges/")
            return DiskCaching(rawImagesDiskCache: FileSystemCache(directoryURL: url!))
        }
        
    }
    
}
