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
    var resource: Resource<[Group.Compact]>!
    var makeTeamDetailVC: (Group.Team) -> UIViewController = runtimeInject
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject

    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivityIndicatorManager!
    
    // MARK: - Cell Fillers
    var teamGroupCellFiller: TeamGroupCellFiller!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(tableView)
        self.avenue = makeAvenue(CGSize(width: 30, height: 30))
        self.teamGroupCellFiller = TeamGroupCellFiller(avenue: avenue)
        configure(avenue)
        self.pullToRefreshActivities = make()
        registerFor3DTouch()
        resource.load(errorDelegate: self, completion: reloadData(with:source:))
    }
    
    fileprivate func reloadData(with groups: [Group.Compact], source: Source) {
        if self.groups.isEmpty && source.isAbsoluteTruth {
            self.groups = groups
            tableView.insertSections(IndexSet.init(integersIn: 0 ... groups.count - 1), with: UITableViewRowAnimation.top)
        } else {
            self.groups = groups
            tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        resource.reload(connectingToIndicator: pullToRefreshActivities,
                        errorDelegate: self,
                        completion: reloadData(with:source:))
    }
    
    func didFetchImage(with url: URL) {
        var paths: [IndexPath] = []
        for (group, groupIndex) in zip(groups, groups.indices) {
            for (team, teamIndex) in zip(group.teams, group.teams.indices) {
                if team.badges.large == url {
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
        teamGroupCellFiller.setup(cell, with: groupTeam, forRowAt: indexPath, afterImageDownload: afterImageDownload)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let team = groups[indexPath.section].teams[indexPath.row]
        let detail = makeTeamDetailVC(team)
        show(detail, sender: self)
    }
}

// MARK: - Configurations
extension GroupsTableViewController {
    
    fileprivate func registerFor3DTouch() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    fileprivate func configure(_ avenue: Avenue<URL, URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = { er, _ in
            print(er)
        }
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "TeamGroupTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "GroupsListTeam")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
}

extension GroupsTableViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        let team = groups[indexPath.section].teams[indexPath.row]
        let teamDetailVC = makeTeamDetailVC(team)
        
        let cellRect = tableView.rectForRow(at: indexPath)
        let sourceRect = previewingContext.sourceView.convert(cellRect, from: tableView)
        previewingContext.sourceRect = sourceRect
        
        return teamDetailVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
