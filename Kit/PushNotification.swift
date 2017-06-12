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

public protocol PushNotificationProtocol {
    
    associatedtype Content
    
    var content: Content { get }
    
    init(payload: [String : Any]) throws
    
}

extension PushNotificationProtocol {
    
    public init?(userInfo: [AnyHashable : Any]) {
        if let content = userInfo as? [String : Any] {
            try? self.init(payload: content)
        } else {
            return nil
        }
    }
    
}

public struct RawPushNotification : PushNotificationProtocol {
    
    public let content: [String : Any]
    
    public init(payload: [String : Any]) throws {
        try self.init(from: payload)
    }
        
}

public struct PushNotification<Content : InMappable> : PushNotificationProtocol {
    
    public let content: Content
    
    public init(payload: [String : Any]) throws {
        let push = try RawPushNotification(payload: payload)
        try self.init(push)
    }
    
    public init(_ pushNotification: RawPushNotification) throws {
        self.content = try! Content(from: pushNotification.content)
    }
    
}

extension RawPushNotification : Mappable {
    
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
