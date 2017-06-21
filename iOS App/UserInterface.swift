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
        subscribe()
        prefetch()
    }
    
    static func makeResources(with logic: Application) -> Resources {
        let resources = Resources(api: logic.api, apiCache: logic.apiCache, networkActivity: .application)
        return resources
    }
    
    func subscribe() {
        logic.notifications.didReceiveNotificationResponse.proxy
            .subscribe(self, with: UserInterface.handleNotificationResponse)
    }
    
    func prefetch() {
        resources.prefetchAll()
        self.prefetchFavorites()
    }
    
    func prefetchFavorites() {
        logic.favoriteTeams.registry.all.forEach({ self.resources.fullTeam($0).prefetch() })
    }
    
    var tabBarController: UITabBarController! {
        return window.rootViewController as? UITabBarController
    }
    
    func start() {
        let viewControllers = tabBarController.viewControllers?.flatMap({ $0 as? UINavigationController }).flatMap({ $0.viewControllers.first })
        let matchesList = viewControllers?.flatMap({ $0 as? MatchesTableViewController }).first
        inject(to: matchesList!)
        let teamsList = viewControllers?.flatMap({ $0 as? TeamsTableViewController }).first
        inject(to: teamsList!)
        let groupsList = viewControllers?.flatMap({ $0 as? GroupsTableViewController }).first
        inject(to: groupsList!)
    }
    
    private func makeAvenue(forImageSize imageSize: CGSize) -> Avenue<URL, URL, UIImage> {
        return logic.images.makeAvenue(forImageSize: imageSize, activityIndicator: .application)
    }
    
    func inject(to teamsList: TeamsTableViewController) {
        teamsList <- {
            $0.resource = self.resources.teams
            $0.isFavorite = self.logic.favoriteTeams.registry.isFavorite(id:)
            $0.updateFavorite = { self.logic.favoriteTeams.registry.updateFavorite(id: $0, isFavorite: $1) }
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            $0.makeTeamDetailVC = { self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded(), onFavorite: $1) }
        }
    }
    
    func isFavoriteMatch(_ match: Match.Compact) -> Bool {
        return match.isFavorite(isFavoriteMatch: self.logic.favoriteMatches.registry.isFavorite,
                                isFavoriteTeam: self.logic.favoriteTeams.registry.isFavorite)
    }
    
    func inject(to matchesList: MatchesTableViewController) {
        matchesList <- {
            $0.resource = self.resources.stages
            $0.isFavorite = isFavoriteMatch(_:)
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            let shouldReload = self.logic.favoriteTeams.registry.unitedDidUpdate.proxy.void()
                .merged(with: self.logic.favoriteMatches.registry.unitedDidUpdate.proxy.void())
            $0.shouldReloadData = shouldReload.mainThread()
            $0.makeMatchDetailVC = { self.matchDetailViewController(for: $0.id, preloaded: $0.preloaded()) }
        }
    }
    
    func inject(to groupsList: GroupsTableViewController) {
        groupsList <- {
            $0.resource = self.resources.groups
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded()) }
        }
    }
    
    func teamDetailViewController(for teamID: Team.ID,
                                  preloaded: TeamDetailPreLoaded,
                                  onFavorite: @escaping () -> () = {  }) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            $0.resource = self.resources.fullTeam(teamID)
            $0.isFavorite = { self.logic.favoriteTeams.registry.isFavorite(id: teamID) }
            $0.updateFavorite = {
                self.logic.favoriteTeams.registry.updateFavorite(id: teamID, isFavorite: $0)
                onFavorite()
            }
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            $0.preloadedTeam = preloaded
            $0.makeTeamDetailVC = { return self.teamDetailViewController(for: $0.id, preloaded: $0.preLoaded(), onFavorite: onFavorite) }
            $0.makeMatchDetailVC = { self.matchDetailViewController(for: $0.id, preloaded: $0.preloaded()) }
        }
    }
    
    func matchDetailViewController(for matchID: Match.ID, preloaded: MatchDetailPreLoaded) -> MatchDetailTableViewController {
        return Storyboard.Main.matchDetailTableViewController.instantiate() <- {
            $0.resource = self.resources.fullMatch(matchID)
            $0.makeAvenue = self.makeAvenue(forImageSize:)
            $0.preloadedMatch = preloaded
            $0.isFavorite = { self.logic.favoriteMatches.registry.isFavorite(id: matchID) }
            $0.updateFavorite = { self.logic.favoriteMatches.registry.updateFavorite(id: matchID, isFavorite: $0) }
        }
    }
    
    func handleNotificationResponse(_ notificationResponse: NotificationResponse) {
        guard let match = try? Match.Full(from: notificationResponse.notification.content) else {
            fault("Not match")
            return
        }
        switch notificationResponse.action {
        case .open:
            openMatch(match: match)
        case .unsubscribe:
            unsubscribe(from: match)
        }
    }
    
    func unsubscribe(from match: Match.Full) {
        printWithContext("Unsubscribing")
        logic.unsubscribedMatches.registry.updateFavorite(id: match.id, isFavorite: true)
    }
    
    func openMatch(match: Match.Full) {
        let vc = matchDetailViewController(for: match.id, preloaded: match.preloaded())
        if let selected = tabBarController.selectedViewController {
            selected.show(vc, sender: selected)
        }
    }
    
}
