//
//  Caches.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Avenues

public final class Caches {
    
    internal var caches: [Int : Storage<URL, UIImage>] = [:]
    
    public let imageCache30px: Avenues.Storage<URL, UIImage>
    
    public init() {
        self.imageCache30px = ImageNSCache()
            .mapValue(inTransform: { assert(max($0.size.width, $0.size.height) == 30); return $0 },
                      outTransform: { assert(max($0.size.width, $0.size.height) == 30); return $0 })
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
    
}
