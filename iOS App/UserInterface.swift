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
    
    init(window: UIWindow, application: Application) {
        self.window = window
        self.logic = application
        self.resources = UserInterface.makeResources(with: application)
        prefetch()
    }
    
    static func makeResources(with logic: Application) -> Resources {
        let resources = Resources(api: logic.api, apiCache: logic.apiCache, networkActivity: .application)
        return resources
    }
    
    func prefetch() {
        resources.prefetchAll()
        logic.favoriteTeams.favoriteTeams.retrieve { (result) in
            print("Before favs prefetch is main thread:", Thread.isMainThread)
            if let set = result.value {
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
    
    private func makeAvenue(forImageSize imageSize: CGSize) -> Avenue<URL, URL, UIImage> {
        return logic.images.makeAvenue(forImageSize: imageSize)
            .connectingNetworkActivityIndicator(manager: .application)
    }
    
    func inject(to teamsList: TeamsTableViewController) {
        teamsList <- {
            $0.resource = self.resources.teams
            $0.isFavorite = self.logic.favoriteTeams.isFavorite(teamWith:)
            $0.updateFavorite = self.logic.favoriteTeams.updateFavorite(id:isFavorite:)
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            $0.makeTeamDetailVC = { self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            $0.resource = self.resources.stages
            $0.isFavorite = self.logic.favoriteTeams.isFavorite(teamWith:)
            $0.makeAvenue = { self.logic.images.makeAvenue(forImageSize: $0) }
            $0.shouldReloadData = self.logic.favoriteTeams.didUpdateFavorite.proxy.void()
        }
    }
    
    func inject(to groupsList: GroupsTableViewController) {
        groupsList <- {
            $0.resource = self.resources.groups
            $0.makeAvenue = { self.logic.images.makeAvenue(forImageSize: $0) }
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func teamDetailViewController(for teamID: Team.ID, preloaded: TeamDetailPreLoaded) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            $0.resource = self.resources.fullTeam(teamID)
            $0.isFavorite = { self.logic.favoriteTeams.isFavorite(teamWith: teamID) }
            $0.makeAvenue = { self.logic.images.makeAvenue(forImageSize: $0) }
            $0.preloadedTeam = preloaded
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
}
