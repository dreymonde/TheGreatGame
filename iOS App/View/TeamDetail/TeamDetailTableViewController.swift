//
//  TeamDetailTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

struct TeamDetailPreLoaded {
    
    let name: String?
    let shortName: String?
    
}

extension Team.Compact {
    
    func preLoaded() -> TeamDetailPreLoaded {
        return TeamDetailPreLoaded(name: self.name, shortName: self.shortName)
    }
    
}

extension Group.Team {
    
    func preLoaded() -> TeamDetailPreLoaded {
        return TeamDetailPreLoaded(name: self.name, shortName: nil)
    }
    
}

class TeamDetailTableViewController: TheGreatGame.TableViewController, Refreshing {
    
    // MARK: - Data source
    var team: Team.Full?
    
    // MARK: - Injections
    var preloadedTeam: TeamDetailPreLoaded?
    var provider: ReadOnlyCache<Void, Team.Full>!
    var makeTeamDetailVC: (Group.Team) -> UIViewController = runtimeInject
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject

    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.avenue = makeAvenue(CGSize(width: 30, height: 30))
        self.pullToRefreshActivities = make()
        registerFor3DTouch()
        configure(tableView)
        configure(avenue)
        configure(navigationItem)
        loadFullTeam()
    }
    
    fileprivate func loadFullTeam(onFinish: @escaping () -> () = { }) {
        provider.retrieve { (result) in
            assert(Thread.isMainThread)
            onFinish()
            if let team = result.asOptional {
                self.team = team
                self.tableView.reloadData()
                self.configure(self.navigationItem)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        pullToRefreshActivities.increment()
        loadFullTeam {
            self.pullToRefreshActivities.decrement()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    let detailSectionIndex = 0
    let groupSectionIndex = 1
    let matchesSectionIndex = 2
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case detailSectionIndex:
            return 1
        case groupSectionIndex:
            return team?.group.teams.count ?? 0
        case matchesSectionIndex:
            return team?.matches.count ?? 0
        default:
            fatalError("What?!")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case groupSectionIndex:
            return team?.group.title
        default:
            return nil
        }
    }
        
    func didFetchImage(with url: URL) {
        guard let team = team else {
            return
        }
        var paths: [IndexPath] = []
        for (match, index) in zip(team.matches, team.matches.indices) {
            if match.teams.map({ $0.badgeURL }).contains(url) {
                paths.append(IndexPath.init(row: index, section: matchesSectionIndex))
            }
        }
        for (team, index) in zip(team.group.teams, team.group.teams.indices) {
            if team.badgeURL == url {
                paths.append(IndexPath.init(row: index, section: groupSectionIndex))
            }
        }
        for indexPath in paths {
            if let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, forRowAt: indexPath, afterImageDownload: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case detailSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TeamDetailTeamDetail", for: indexPath)
            configureCell(cell, forRowAt: indexPath)
            return cell
        case groupSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TeamDetailGroupTeam", for: indexPath)
            configureCell(cell, forRowAt: indexPath)
            return cell
        case matchesSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TeamDetailMatch", for: indexPath)
            configureCell(cell, forRowAt: indexPath)
            return cell
        default:
            fatalError("What?!")
        }
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let match as MatchTableViewCell:
            configureMatchCell(match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        case let teamGroup as TeamGroupTableViewCell:
            configureTeamGroupCell(teamGroup, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            configureTeamDetailsCell(cell, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        }
    }
    
    func configureTeamDetailsCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        if let team = team {
            cell.textLabel?.text = team.name
            cell.detailTextLabel?.text = team.shortName
        } else if let preloaded = preloadedTeam {
            cell.textLabel?.text = preloaded.name
            cell.detailTextLabel?.text = preloaded.shortName
        }
    }
    
    func configureMatchCell(_ cell: MatchTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        guard let match = team?.matches[indexPath.row] else {
            fault("No team still?")
            return
        }
        if !afterImageDownload {
            avenue.prepareItem(at: match.home.badgeURL)
            avenue.prepareItem(at: match.away.badgeURL)
        }
        cell.scoreTimeLabel.text = "-:-"
        cell.homeTeamNameLabel.text = match.home.name
        cell.awayTeamNameLabel.text = match.away.name
        cell.homeBadgeImageView.setImage(avenue.item(at: match.home.badgeURL), afterDownload: afterImageDownload)
        cell.awayBadgeImageView.setImage(avenue.item(at: match.away.badgeURL), afterDownload: afterImageDownload)
    }
    
    func configureTeamGroupCell(_ cell: TeamGroupTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        guard let groupTeam = team?.group.teams[indexPath.row] else {
            fault("No team, really?")
            return
        }
        if !afterImageDownload {
            avenue.prepareItem(at: groupTeam.badgeURL)
        }
        cell.nameLabel.text = groupTeam.name
        cell.pointsLabel.text = String(groupTeam.points)
        cell.positionLabel.text = "\(indexPath.row + 1)."
        cell.badgeImageView.setImage(avenue.item(at: groupTeam.badgeURL), afterDownload: afterImageDownload)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case groupSectionIndex:
            guard let team = self.team?.group.teams[indexPath.row] else {
                return
            }
            let anotherTeamVC = makeTeamDetailVC(team)
            show(anotherTeamVC, sender: self)
        default:
            break
        }
    }

}

// MARK: - Configurations
extension TeamDetailTableViewController {
    
    fileprivate func registerFor3DTouch() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    fileprivate func configure(_ navigationItem: UINavigationItem) {
        navigationItem.title = team?.name ?? preloadedTeam?.name
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView <- {
            $0.register(UINib.init(nibName: "MatchTableViewCell", bundle: nil), forCellReuseIdentifier: "TeamDetailMatch")
            $0.register(UINib.init(nibName: "TeamGroupTableViewCell", bundle: nil), forCellReuseIdentifier: "TeamDetailGroupTeam")
            $0.estimatedRowHeight = 55
            $0.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    fileprivate func configure(_ avenue: SymmetricalAvenue<URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = jprint
    }
    
}

extension TeamDetailTableViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        var vc: UIViewController?
        switch indexPath.section {
        case groupSectionIndex:
            guard let teamGroup = team?.group.teams[indexPath.row] else {
                return nil
            }
            vc = makeTeamDetailVC(teamGroup)
        default:
            return nil
        }
        
        let cellRect = tableView.rectForRow(at: indexPath)
        let sourceRect = previewingContext.sourceView.convert(cellRect, from: tableView)
        previewingContext.sourceRect = sourceRect
        
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
