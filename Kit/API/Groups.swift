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
    
    public let path: APIPath
    
    init(path: APIPath) {
        self.path = "groups" + path
    }
    
    public static let all = GroupsEndpoint(path: "all.json")
    
}

public final class GroupsAPI : APIPoint {
    
    public let provider: ReadOnlyStorage<GroupsEndpoint, [String : Any]>
    public let all: Retrieve<Editioned<Groups>>
    
    private let dataProvider: ReadOnlyStorage<APIPath, Data>
    
    public init(dataProvider: ReadOnlyStorage<APIPath, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Groups>.self)
    }
    
}

public final class GroupsAPICache : APICachePoint {
    
    public let provider: Storage<GroupsEndpoint, [String : Any]>
    public let all: Storage<Void, Editioned<Groups>>
    
    private let dataProvider: Storage<APIPath, Data>
    
    public init(dataProvider: Storage<APIPath, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Groups>.self)
    }
    
}
