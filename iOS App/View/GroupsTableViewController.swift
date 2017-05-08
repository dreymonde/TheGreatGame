//
//  GroupsListTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

class GroupsTableViewController: TheGreatGame.TableViewController, Refreshing {

    // MARK: - Data source
    var groups: [Group.Compact] = []
    
    // MARK: - Injections
    var provider: ReadOnlyCache<Void, [Group.Compact]>!
    var imageCache: Storage<URL, UIImage>!
    var makeTeamDetailVC: (Group.Team) -> UIViewController = runtimeInject
    
    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(tableView)
        self.avenue = make()
        configure(avenue)
        self.pullToRefreshActivities = make()
        loadGroups()
    }
    
    fileprivate func loadGroups(onFinish: @escaping () -> () = { }) {
        provider.retrieve { (groupsResult) in
            assert(Thread.isMainThread)
            onFinish()
            print(groupsResult)
            if let groups = groupsResult.asOptional {
                self.reloadData(with: groups)
            }
        }
    }
    
    fileprivate func reloadData(with groups: [Group.Compact]) {
//        if self.groups.isEmpty {
//            self.groups = groups
//            var paths: [IndexPath] = []
//            for (group, groupIndex) in zip(groups, groups.indices) {
//                for (team, teamIndex) in zip(group.teams, group.teams.indices) {
//                    paths.append(IndexPath.init(row: teamIndex, section: groupIndex))
//                }
//            }
//            tableView.insertRows(at: paths, with: UITableViewRowAnimation.automatic)
//        } else {
            self.groups = groups
            tableView.reloadData()
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        pullToRefreshActivities.increment()
        loadGroups {
            self.pullToRefreshActivities.decrement()
        }
    }
    
    func didFetchImage(with url: URL) {
        var paths: [IndexPath] = []
        for (group, groupIndex) in zip(groups, groups.indices) {
            for (team, teamIndex) in zip(group.teams, group.teams.indices) {
                if team.badgeURL == url {
                    paths.append(IndexPath.init(row: teamIndex, section: groupIndex))
                }
            }
        }
        for indexPath in paths {
            if let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, forRowAt: indexPath, afterImageDownload: true)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].teams.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsListTeam", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let match as TeamGroupTableViewCell:
            configureTeamGroupCell(match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureTeamGroupCell(_ cell: TeamGroupTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        let groupTeam = groups[indexPath.section].teams[indexPath.row]
        if !afterImageDownload {
            avenue.prepareItem(at: groupTeam.badgeURL)
        }
        cell.nameLabel.text = groupTeam.name
        cell.pointsLabel.text = String(groupTeam.points)
        cell.positionLabel.text = "\(indexPath.row + 1)."
        cell.badgeImageView.setImage(avenue.item(at: groupTeam.badgeURL), afterDownload: afterImageDownload)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let team = groups[indexPath.section].teams[indexPath.row]
        let detail = makeTeamDetailVC(team)
        show(detail, sender: self)
    }
}

// MARK: - Configurations
extension GroupsTableViewController {
    
    fileprivate func make() -> SymmetricalAvenue<URL, UIImage> {
        let lane = URLSessionProcessor(session: URLSession(configuration: .ephemeral))
            .connectingNetworkActivityIndicator()
            .mapImage()
            .mapValue({ $0.resized(toFit: CGSize(width: 30, height: 30)) })
        return Avenue(storage: imageCache, processor: lane)
    }
    
    fileprivate func configure(_ avenue: Avenue<URL, URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = {
            print($0)
        }
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "TeamGroupTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "GroupsListTeam")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
}
