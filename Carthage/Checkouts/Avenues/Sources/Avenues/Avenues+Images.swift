//
//  Avenues+Images.swift
//  Avenues
//
//  Created by Олег on 12.02.2018.
//  Copyright © 2018 Avenues. All rights reserved.
//

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import AppKit
#endif


#if os(iOS) || os(tvOS) || os(watchOS)
    
    extension Avenue {
        
        public static func images() -> Avenue<URL, UIImage> {
            let session = URLSessionProcessor(sessionConfiguration: .default)
                .mapImages()
            let memoryCache = NSCacheCache<NSURL, UIImage>()
                .mapKeys(to: URL.self, { $0 as NSURL })
            return Avenue<URL, UIImage>(cache: memoryCache, processor: session)
        }
        
    }
    
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
    
    public extension ProcessorProtocol where Value == Data {
        
        func mapImages() -> Processor<Key, UIImage> {
            return mapValues(UIImage.fromData)
        }
        
    }
    
    public enum UIImageDataConversionError : Error {
        case cannotConvertFromData
    }
    
    extension UIImage {
        
        internal static func fromData(_ data: Data) throws -> UIImage {
            if let image = self.init(data: data) {
                return image
            } else {
                throw UIImageDataConversionError.cannotConvertFromData
            }
        }
        
    }
    
#endif

#if os(iOS) || os(tvOS)
    
    extension Avenue where Value == UIImage {
        
        public func register(_ imageView: UIImageView, for resourceKey: Key) {
            self.register(imageView, for: resourceKey, setup: { (view, imageState) in
                view.image = imageState.value
            })
        }
        
    }
    
#endif

#if os(watchOS)
    
    extension Avenue where Value == UIImage {
        
        public func register(_ interfaceImage: WKInterfaceImage, for resourceKey: Key) {
            self.register(interfaceImage, for: resourceKey, setup: { (interface, imageState) in
                interface.setImage(imageState.value)
            })
        }
        
    }

#endif

#if os(macOS)
    
    extension Avenue {
        
        public static func images() -> Avenue<URL, NSImage> {
            let session = URLSessionProcessor(sessionConfiguration: .default)
                .mapImages()
            let memoryCache = NSCacheCache<NSURL, NSImage>()
                .mapKeys(to: URL.self, { $0 as NSURL })
            return Avenue<URL, NSImage>(cache: memoryCache, processor: session)
        }
        
    }
    
    extension Avenue where Value == NSImage {
        
        public func register(_ imageView: NSImageView, for resourceKey: Key) {
            self.register(imageView, for: resourceKey, setup: { (view, imageState) in
                view.image = imageState.value
            })
        }
        
    }
    
    public extension ProcessorProtocol where Value == Data {
        
        func mapImages() -> Processor<Key, NSImage> {
            return mapValues(NSImage.fromData)
        }
        
    }
    
    public enum NSImageDataConversionError : Error {
        case cannotConvertFromData
    }
    
    extension NSImage {
        
        internal static func fromData(_ data: Data) throws -> NSImage {
            if let image = self.init(data: data) {
                return image
            } else {
                throw NSImageDataConversionError.cannotConvertFromData
            }
        }
        
    }
    
#endif

