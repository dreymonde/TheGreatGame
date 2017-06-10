//
//  PushNotifications.swift
//  TheGreatGame
//
//  Created by Олег on 31.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public struct PushToken {
    
    public let rawToken: Data
    public var string: String {
        return rawToken.reduce("", { $0 + String(format: "%02.2hhx", $1) })
    }
    
    public init(_ token: Data) {
        self.rawToken = token
    }
    
}

extension PushToken : CustomStringConvertible {
    
    public var description: String {
        return string
    }
    
}

public struct PushNotification {
    
    public let content: [String : Any]
    
    public init?(userInfo: [AnyHashable : Any]) {
        if let content = userInfo as? [String : Any] {
            try? self.init(from: content)
        }
        return nil
    }
        
}

extension PushNotification : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case aps, content
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.content = try mapper.unsafe_map(from: .content)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.unsafe_map(self.content, to: .content)
    }
    
}
