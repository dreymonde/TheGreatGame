//
//  PushNotifications.swift
//  TheGreatGame
//
//  Created by Олег on 31.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public struct PushToken : Equatable {
    
    public let rawToken: Data
    public var string: String {
        return rawToken.reduce("", { $0 + String(format: "%02.2hhx", $1) })
    }
    
    public init(_ token: Data) {
        self.rawToken = token
    }
    
    public static func == (lhs: PushToken, rhs: PushToken) -> Bool {
        return lhs.rawToken == rhs.rawToken
    }
    
}

extension PushToken : CustomStringConvertible {
    
    public var description: String {
        return string
    }
    
}

enum PushPayloadError : Error {
    case notValidContent([AnyHashable : Any])
}

public struct PushNotification {
    
    public let content: [String : Any]
    
    public init(payload: [String : Any]) throws {
        try self.init(from: payload)
    }
    
    public func extract<MappableType : InMappable>(_ type: MappableType.Type) throws -> MappableType {
        return try MappableType(from: content)
    }
        
}

extension PushNotification {
    
    public init(userInfo: [AnyHashable : Any]) throws {
        if let content = userInfo as? [String : Any] {
            try self.init(payload: content)
        } else {
            throw PushPayloadError.notValidContent(userInfo)
        }
    }
    
}

extension PushNotification : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case aps, content
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.content = try mapper.unsafe_map(from: .content)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.unsafe_map(self.content, to: .content)
    }
    
}
