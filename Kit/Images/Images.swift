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

public final class Images : Storing {
    
    public static var preferredSubPath: String {
        return "image-cache-10"
    }
    
    internal var caches: [Int : Storage<URL, UIImage>] = [:]
    
    fileprivate let imageFetchingSession = URLSession(configuration: .default)
    fileprivate let diskCache: Cache<URL, UIImage>
    
    public init(diskCache: Cache<String, Data>) {
        self.diskCache = diskCache
            .mapKeys({ $0.absoluteString })
            .mapImage()
    }
    
    public init(imageCache: Cache<URL, UIImage>) {
        self.diskCache = imageCache
    }
        
    public func imageCache(forSize side: CGFloat) -> Storage<URL, UIImage> {
        let intside = Int(side)
        if let existing = caches[intside] {
            return existing
        } else {
            let new: Storage<URL, UIImage> = Storage(ImageNSCache())
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
    
    public func makeAvenue(forImageSize imageSize: CGSize, activityIndicator: NetworkActivityIndicatorManager) -> Avenue<URL, URL, UIImage> {
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
