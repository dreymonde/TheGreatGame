//
//  Groups.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public struct GroupsEndpoint {
    
    public let path: String
    
    init(path: String) {
        self.path = "groups/\(path)"
    }
    
    public static let all = GroupsEndpoint(path: "all.json")
    
}

public final class GroupsAPI : APIPoint {
    
    public let provider: ReadOnlyCache<GroupsEndpoint, [String : Any]>
    public let all: ReadOnlyCache<Void, Editioned<Groups>>
    
    private let dataProvider: ReadOnlyCache<String, Data>
    
    public init(rawDataProvider: ReadOnlyCache<String, Data>) {
        self.dataProvider = rawDataProvider
        self.provider = rawDataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Groups>.self)
    }
    
}
