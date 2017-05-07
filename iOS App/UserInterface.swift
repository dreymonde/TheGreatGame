//
//  UserInterface.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Shallows
import TheGreatKit

final class UserInterface {
    
    fileprivate let window: UIWindow
    fileprivate let logic: Application
    
    init(window: UIWindow, application: Application) {
        self.window = window
        self.logic = application
    }
    
    func start() {
        let viewControllers = (window.rootViewController as? UITabBarController)?.viewControllers?.flatMap({ $0 as? UINavigationController }).flatMap({ $0.viewControllers.first })
        let matchesList = viewControllers?.flatMap({ $0 as? MatchesTableViewController }).first
        inject(to: matchesList!)
        let teamsList = viewControllers?.flatMap({ $0 as? TeamsTableViewController }).first
        inject(to: teamsList!)
    }
    
    func inject(to teamsList: TeamsTableViewController) {
        teamsList <- {
            $0.teamsProvider = logic.api.teams.all
                .mapValues({ $0.content.teams })
                .mainThread()
                .connectingNetworkActivityIndicator()
            $0.fullTeamProvider = logic.api.teams.fullTeam
                .mapValues({ $0.content })
                .connectingNetworkActivityIndicator()
                .mainThread()
        }
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            $0.matchesProvider = logic.api.matches.all
                .mapValues({ $0.content.matches })
                .connectingNetworkActivityIndicator()
                .mainThread()
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
