//
//  Caches.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Shallows
import Avenues
import UIKit

extension Shallows.StorageProtocol where Value == Data {
    
    public func mapImage() -> Shallows.Storage<Key, UIImage> {
        return mapValues(transformIn: { try UIImage.init(data: $0, scale: 2.0).unwrap() },
                         transformOut: throwing(UIImagePNGRepresentation))
    }
    
}

public final class Images : SimpleStoring {
    
    public static func preferredSubpath(from dataDir: data_dir) -> SubpathName {
        return dataDir.images
    }
    
    internal enum SideSize { }
    
    internal var caches: [IntType<SideSize> : Avenues.Storage<URL, UIImage>] = [:]
    
    fileprivate let imageFetchingSession = URLSession(configuration: .default)
    fileprivate let diskCache: Shallows.Storage<URL, UIImage>
    
    public init(diskStorage: DiskStorage) {
        self.diskCache = diskStorage
            .mapKeys({ Filename(rawValue: $0.absoluteString) })
            .mapImage()
    }
    
    public init(imageCache: Shallows.Storage<URL, UIImage>) {
        self.diskCache = imageCache
    }
        
    public func imageCache(forSize side: CGFloat) -> Avenues.Storage<URL, UIImage> {
        let intside = IntType<SideSize>(Int(side))
        if let existing = caches[intside] {
            return existing
        } else {
            let new: Avenues.Storage<URL, UIImage> = Storage(ImageNSCache())
                //.mapValue(inTransform: { assert(max($0.size.width, $0.size.height) == side); return $0 },
                //          outTransform: { assert(max($0.size.width, $0.size.height) == side); return $0 })
            caches[intside] = new
            return new
        }
    }
    
    public func makeNotSizedAvenue() -> Avenue<URL, URL, UIImage> {
        let fullSizedLane: Processor<URL, UIImage> = URLSessionProcessor(session: imageFetchingSession)
            .mapImage()
            .caching(to: diskCache)
        let storage = Storage(ImageNSCache())
        return Avenue(storage: storage, processor: fullSizedLane)
    }
    
    public func makeAvenue(forImageSize imageSize: CGSize, activityIndicator: NetworkActivityIndicator) -> Avenue<URL, URL, UIImage> {
        let fullSizedLane: Processor<URL, UIImage> = URLSessionProcessor(session: imageFetchingSession)
            .mapImage()
            .connectingNetworkActivityIndicator(manager: activityIndicator)
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

extension ReadOnlyStorage {
    
    public static func empty() -> ReadOnlyStorage<Key, Value> {
        return ReadOnlyStorage(storageName: "empty", retrieve: { (_, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        })
    }
    
}

extension Shallows.Storage {
    
    public static func empty() -> Storage<Key, Value> {
        return Storage(storageName: "empty", retrieve: { (_, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        }, set: { (_, _, completion) in
            completion(.failure(EmptyCacheError.cacheIsAlwaysEmpty))
        })
    }
    
}
