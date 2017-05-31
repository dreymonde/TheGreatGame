//
//  PushNotifications.swift
//  TheGreatGame
//
//  Created by Олег on 31.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public struct PushNotification {
    
    public let content: [String : Any]
    
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
