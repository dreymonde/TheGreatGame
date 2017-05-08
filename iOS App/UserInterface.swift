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
        let groupsList = viewControllers?.flatMap({ $0 as? GroupsTableViewController }).first
        inject(to: groupsList!)
    }
    
    func inject(to teamsList: TeamsTableViewController) {
        teamsList <- {
            $0.provider = logic.api.teams.all
                .mapValues({ $0.content.teams })
                .mainThread()
                .connectingNetworkActivityIndicator()
            $0.imageCache = logic.caches.imageCache30px
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            $0.provider = logic.api.matches.all
                .mapValues({ $0.content.matches })
                .connectingNetworkActivityIndicator()
                .mainThread()
            $0.imageCache = logic.caches.imageCache30px
        }
    }
    
    func inject(to groupsList: GroupsTableViewController) {
        groupsList <- {
            $0.provider = logic.api.groups.all
                .mapValues({ $0.content.groups })
                .connectingNetworkActivityIndicator()
                .mainThread()
            $0.imageCache = logic.caches.imageCache30px
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func teamDetailViewController(for teamID: Team.ID, preloaded: TeamDetailPreLoaded) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            $0.provider = logic.api.teams.fullTeam
                .mapValues({ $0.content })
                .singleKey(teamID)
                .connectingNetworkActivityIndicator()
                .mainThread()
            $0.imageCache = logic.caches.imageCache30px
            $0.preloadedTeam = preloaded
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
}

extension ReadOnlyCache {
    
    func mainThread() -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache.init(cacheName: self.cacheName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.main.async {
                    completion(result)
                }
            })
        })
    }
    
}
