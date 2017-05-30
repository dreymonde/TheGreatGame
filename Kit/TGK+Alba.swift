//
//  TGK+Alba.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba

extension Subscribe {
    
    public func mainThread() -> Subscribe<Event> {
        return rawModify(subscribe: { (id, handler) in
            self.manual.subscribe(objectWith: id, with: { (event) in
                DispatchQueue.main.async { handler(event) }
            })
        }, entry: ProxyPayload.Entry.custom("main-thread"))
    }
    
}
