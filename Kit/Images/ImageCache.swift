//
//  ImageCache.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Avenues
import UIKit.UIImage

public final class ImageNSCache : Avenues.MemoryCacheProtocol {
    
    let internalCache = NSCache<NSURL, UIImage>()
    
    public typealias Key = URL
    public typealias Value = UIImage
    
    public func value(forKey key: URL) -> UIImage? {
        return internalCache.object(forKey: key as NSURL)
    }
    
    public func set(_ value: UIImage, forKey key: URL) {
        internalCache.setObject(value, forKey: key as NSURL)
    }
    
    public func remove(valueAt key: URL) {
        internalCache.removeObject(forKey: key as NSURL)
    }
    
}
