//
//  UserInterface.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Shallows

final class UserInterface {
    
    fileprivate let window: UIWindow
    fileprivate let logic: Application
    
    init(window: UIWindow, application: Application) {
        self.window = window
        self.logic = application
    }
    
    func start() {
        let teamsList = (window.rootViewController as? UINavigationController)?.viewControllers.first as! TeamsTableViewController
        inject(to: teamsList)
    }
    
    func inject(to teamsList: TeamsTableViewController) {
        teamsList <- {
            $0.teamsProvider = logic.teamsAPI.all.mapValues({ $0.content.teams })
                .mainThread()
                .connectingNetworkActivityIndicator()
            $0.fullTeamProvider = logic.teamsAPI.fullTeam.mapValues({ $0.content })
                .mainThread()
                .connectingNetworkActivityIndicator()
        }
    }
    
}

extension ReadOnlyCache {
    
    func mainThread() -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache.init(name: self.name, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.main.async {
                    completion(result)
                }
            })
        })
    }
    
}
