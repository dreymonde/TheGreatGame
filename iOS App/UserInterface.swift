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
import Avenues

final class UserInterface {
    
    fileprivate let window: UIWindow
    fileprivate let logic: Application
    fileprivate let resources: Resources
    
    fileprivate let avenueSession = URLSession(configuration: .ephemeral)
    
    init(window: UIWindow, application: Application) {
        self.window = window
        self.logic = application
        self.resources = UserInterface.makeResources(with: application)
        prefetch()
    }
    
    static func makeResources(with logic: Application) -> Resources {
        let resources = Resources(application: logic)
        return resources
    }
    
    func prefetch() {
        resources.prefetchAll()
        logic.favoriteTeams.favoriteTeams.retrieve { (result) in
            print("Before favs prefetch is main thread:", Thread.isMainThread)
            if let set = result.asOptional {
                for id in set {
                    self.resources.fullTeam(id).prefetch()
                }
            }
        }
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
            $0.resource = self.resources.teams
            $0.favoritesProvider = Local(provider: self.logic.favoriteTeams.favoriteTeams)
            $0.updateFavorite = self.logic.favoriteTeams.updateFavorite(id:isFavorite:)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.makeTeamDetailVC = { self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            $0.resource = self.resources.stages
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
        }
    }
    
    func inject(to groupsList: GroupsTableViewController) {
        groupsList <- {
            $0.resource = self.resources.groups
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func teamDetailViewController(for teamID: Team.ID, preloaded: TeamDetailPreLoaded) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            $0.resource = self.resources.fullTeam(teamID)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.preloadedTeam = preloaded
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
}
