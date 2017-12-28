//
//  AvenuesExtensions.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Avenues
import UIKit
import CoreGraphics

extension Avenue {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivityIndicator) -> Avenue<StoringKey, ProcessingKey, Value> {
        let newLane = self.processor.connectingNetworkActivityIndicator(manager: manager)
        return Avenue(storage: storage, processor: newLane)
    }
    
}

extension UIImage {
    
    public func resized(toFit size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")
        
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height
        
        var resizeFactor: CGFloat
        
        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / self.size.width
        } else {
            resizeFactor = size.height / self.size.height
        }
        
        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: origin, size: scaledSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    #if os(iOS)
    
    public func rotate90() -> UIImage {
        
        let size = CGSize(width: self.size.height, height: self.size.width)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { (context) in
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            let bitmap = context.cgContext
            bitmap.translateBy(x: size.width / 2, y: size.height / 2)
            //Rotate the image context
            bitmap.rotate(by: .pi / 2)
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 2.0, y: -1.0)
            
            let origin = CGPoint(x: -size.width / 2, y: -size.width / 2)
            
            bitmap.draw(self.cgImage!, in: CGRect(origin: origin, size: size))
        }
        
        return image
        
    }
    
    public func rotated(by angle: CGFloat) -> UIImage {
        let size = self.size
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { (context) in
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            let bitmap = context.cgContext
            bitmap.translateBy(x: size.width / 2, y: size.height / 2)
            //Rotate the image context
            bitmap.rotate(by: angle)
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            
            let origin = CGPoint(x: -size.width / 2, y: -size.width / 2)
            
            bitmap.draw(self.cgImage!, in: CGRect(origin: origin, size: size))
        }
        
        return image
    }
    
    #endif
    
}
