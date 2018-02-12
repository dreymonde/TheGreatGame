//
//  TeamsTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues
import Alba

extension Set {
    
    mutating func updatePresence(_ element: Element, shouldBeInSet: Bool) {
        if shouldBeInSet {
            insert(element)
        } else {
            remove(element)
        }
    }
    
}

class TeamsTableViewController: TheGreatGame.TableViewController, Showing {
    
    // MARK: - Data source
    var teams: [Team.Compact]!
    
    // MARK: - Injections
    var makeTeamDetailVC: (Team.Compact, _ onFavorite: @escaping () -> ()) -> UIViewController = runtimeInject
    var makeAvenue: (CGSize) -> Avenue<URL, UIImage, UIImageView> = runtimeInject
    
    var isFavorite: (Team.ID) -> Bool = runtimeInject
    var updateFavorite: (Team.ID, Bool) -> () = runtimeInject
    
    // MARK: - Services
    var avenue: Avenue<URL, UIImage, UIImageView>!
    
    // MARK: - Connections
    var reactiveTeams: Reactive<[Team.Compact]>!
    
    override func viewDidLoad() {
        printWithContext(teams.count.description + " teams cached")
        super.viewDidLoad()
        registerForPeekAndPop()
        self.subscribe()
        configure(tableView)
        self.avenue = makeAvenue(CGSize(width: 30, height: 30))
        self.reactiveTeams.update.fire(errorDelegate: self)
    }
    
    func subscribe() {
        reactiveTeams.didUpdate.subscribe(self, with: TeamsTableViewController.reloadData)
    }
    
    fileprivate func reloadData(with teams: [Team.Compact]) {
        if self.teams.isEmpty {
            self.teams = teams
            let ips = teams.indices.map({ IndexPath.init(row: $0, section: 0) })
            tableView.insertRows(at: ips, with: UITableViewRowAnimation.automatic)
        } else {
            self.teams = teams
            tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        reactiveTeams.update.fire(activityIndicator: pullToRefreshIndicator,
                                  errorDelegate: self)
    }
        
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCompact", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch cell {
        case let teamCompact as TeamCompactTableViewCell:
            configureTeamCompactCell(teamCompact, forRowAt: indexPath)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureTeamCompactCell(_ cell: TeamCompactTableViewCell, forRowAt indexPath: IndexPath) {
        let team = teams[indexPath.row]
        let badgeURL = team.badges.large
        cell.favoriteButton.isSelected = isFavorite(team.id)
        cell.nameLabel.text = team.name
        cell.shortNameLabel.text = team.shortName
        avenue.register(imageView: cell.badgeImageView, for: badgeURL)
        cell.onSwitch = { isFavorite in
            if let ipath = self.tableView.indexPath(for: cell) {
                let team = self.teams[ipath.row]
                self.updateFavorite(team.id, isFavorite)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showViewController(for: indexPath)
    }
    
    func viewController(for indexPath: IndexPath) -> UIViewController? {
        let team = teams[indexPath.row]
        return teamDetailViewController(for: team)
    }
    
    fileprivate func teamDetailViewController(for team: Team.Compact) -> UIViewController {
        return makeTeamDetailVC(team, { self.tableView.reloadData() })
    }
    
}

// MARK: - Configurations
extension TeamsTableViewController {
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "TeamCompactTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "TeamCompact")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
}

// MARK: - Peek & Pop
extension TeamsTableViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return viewController(for: location, previewingContext: previewingContext)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
