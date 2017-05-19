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
    
    fileprivate let avenueSession = URLSession(configuration: .ephemeral)
    
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
            let provider = logic.cachier.cachedLocally(logic.api.teams.all, transformKey: { _ in "all-teams" }, token: "all-teams")
                .mapValues({ $0.map({ $0.teams }) })
            $0.resource = ViewResource(provider: zip(provider, self.logic.favoriteTeams.favoriteTeams).mapValues({ $0.0.zipping($0.1) }))
            $0.updateFavorite = self.logic.favoriteTeams.updateFavorite(id:isFavorite:)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            let provider = logic.api.matches.stages
            let cached = logic.cachier.cachedLocally(provider, transformKey: { _ in "all-matches" }, token: "all-matches")
                .mapValues({ $0.map({ $0.stages }) })
            $0.resource = ViewResource(provider: cached)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
        }
    }
    
    func inject(to groupsList: GroupsTableViewController) {
        groupsList <- {
            let provider = logic.api.groups.all
            let cached = logic.cachier.cachedLocally(provider, transformKey: { _ in "all-groups" }, token: "all-groups")
                .mapValues({ $0.map({ $0.groups }) })
            $0.resource = ViewResource(provider: cached)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func teamDetailViewController(for teamID: Team.ID, preloaded: TeamDetailPreLoaded) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            let provider = logic.cachier.cachedLocally(logic.api.teams.fullTeam.singleKey(teamID),
                                                       transformKey: { "\(teamID.rawID)" },
                                                       token: "\(teamID.rawID)-team")
            $0.resource = ViewResource(provider: provider)
            $0.makeAvenue = { self.logic.imageFetching.makeAvenue(forImageSize: $0) }
            $0.preloadedTeam = preloaded
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
}
