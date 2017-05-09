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
        return mapValues(transformIn: throwing(UIImage.init(data:)),
                         transformOut: throwing(UIImagePNGRepresentation))
    }
    
}

public final class ImageFetch {
    
    internal var caches: [Int : Storage<URL, UIImage>] = [:]
    
    fileprivate let imageFetchingSession = URLSession(configuration: .ephemeral)
    fileprivate let diskCaching: DiskCaching?
    
    public init(shouldCacheToDisk: Bool) {
        self.diskCaching = shouldCacheToDisk ? DiskCaching() : nil
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
        let fullSizedLane: Processor<URL, UIImage> = {
            let sessionLane = URLSessionProcessor(session: imageFetchingSession)
                .mapImage()
            if let diskCaching = diskCaching {
                return sessionLane.caching(to: diskCaching.imagesDiskCache)
            }
            return sessionLane
        }()
        let lane = fullSizedLane.mapValue({ $0.resized(toFit: imageSize) })
        let storage = imageCache(forSize: imageSize.width)
        return Avenue(storage: storage, processor: lane)
    }
    
}

extension ImageFetch {
    
    internal final class DiskCaching {
        
        internal let rawImagesDiskCache: FileSystemCache
        internal let imagesDiskCache: Cache<URL, UIImage>
        
        internal init(rawImagesDiskCache: FileSystemCache = .inDirectory(.cachesDirectory, appending: "badges")) {
            self.rawImagesDiskCache = rawImagesDiskCache
            self.imagesDiskCache = rawImagesDiskCache
                .mapImage()
                .mapKeys({ $0.absoluteString })
        }
        
    }
    
}
