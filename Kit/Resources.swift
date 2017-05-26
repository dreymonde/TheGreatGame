//
//  Storage.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit

final class Resources {
    
    var stages: Resource<[Stage]>
    
    init(stages: Resource<[Stage]>) {
        self.stages = stages
    }
    
}
