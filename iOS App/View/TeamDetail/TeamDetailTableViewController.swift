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
    let badges: Team.Badges?
    
}

extension Team.Compact {
    
    func preLoaded() -> TeamDetailPreLoaded {
        return TeamDetailPreLoaded(name: self.name, shortName: self.shortName, badges: self.badges)
    }
    
}

extension Group.Team {
    
    func preLoaded() -> TeamDetailPreLoaded {
        return TeamDetailPreLoaded(name: self.name, shortName: nil, badges: self.badges)
    }
    
}

extension Match.Team {
    
    func preLoaded() -> TeamDetailPreLoaded {
        return TeamDetailPreLoaded(name: self.name, shortName: self.shortName, badges: self.badges)
    }
    
}

class TeamDetailTableViewController: TheGreatGame.TableViewController, Refreshing {
    
    // MARK: - Data source
    var team: Team.Full?
    
    // MARK: - Injections
    var preloadedTeam: TeamDetailPreLoaded?
    var resource: Resource<Team.Full>!
    var makeTeamDetailVC: (Group.Team) -> UIViewController = runtimeInject
    var makeMatchDetailVC: (Match.Compact) -> UIViewController = runtimeInject
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject
    var isFavorite: () -> Bool = runtimeInject

    // MARK: - Services
    var mainBadgeAvenue: SymmetricalAvenue<URL, UIImage>!
    var smallBadgesAvenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivityIndicatorManager!
    
    // MARK: - Cell Fillers
    var matchCellFiller: MatchCellFiller!
    var teamGroupCellFiller: TeamGroupCellFiller!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.smallBadgesAvenue = makeAvenue(CGSize(width: 30, height: 30))
        self.mainBadgeAvenue = makeAvenue(CGSize(width: 50, height: 50))
        self.matchCellFiller = MatchCellFiller(avenue: smallBadgesAvenue,
                                               isFavorite: { _ in return false },
                                               isAbsoluteTruth: { [unowned self] in self.resource.isAbsoluteTruth })
        self.teamGroupCellFiller = TeamGroupCellFiller(avenue: smallBadgesAvenue,
                                                       isAbsoluteTruth: { [unowned self] in self.resource.isAbsoluteTruth })
        self.pullToRefreshActivities = make()
        registerFor3DTouch()
        configure(tableView)
        configure(smallBadges: smallBadgesAvenue)
        configure(mainBadge: mainBadgeAvenue)
        configure(navigationItem)
        self.resource.load(confirmation: tableView.reloadData, completion: self.setup(with:source:))
    }
    
    func setup(with team: Team.Full, source: Source) {
        self.team = team
        self.tableView.reloadData()
        self.configure(self.navigationItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        resource.reload(connectingToIndicator: pullToRefreshActivities, completion: self.setup(with:source:))
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
    
    func didFetchMainBadge() {
        let detailCellIndexPath = IndexPath(row: 0, section: detailSectionIndex)
        if let detailCell = tableView.cellForRow(at: detailCellIndexPath) {
            configureCell(detailCell, forRowAt: detailCellIndexPath, afterImageDownload: true)
        }
    }
    
    func didFetchImage(with url: URL) {
        guard let team = team else {
            return
        }
        var paths: [IndexPath] = []
        for (match, index) in zip(team.matches, team.matches.indices) {
            if match.teams.map({ $0.badges.large }).contains(url) {
                paths.append(IndexPath.init(row: index, section: matchesSectionIndex))
            }
        }
        for (team, index) in zip(team.group.teams, team.group.teams.indices) {
            if team.badges.large == url {
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
        case let teamDetail as TeamDetailInfoTableViewCell:
            configureTeamDetailsCell(teamDetail, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault("Such cell is not registered \(type(of: cell))")
        }
    }
    
    func configureTeamDetailsCell(_ cell: TeamDetailInfoTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        cell.selectionStyle = .none
        if let team = team {
            mainBadgeAvenue.prepareItem(at: team.badges.large)
            cell.nameLabel.text = team.name
            cell.badgeImageView.image = mainBadgeAvenue.item(at: team.badges.large)
        } else if let preloaded = preloadedTeam {
            cell.nameLabel.text = preloaded.name
            if let badgeURL = preloaded.badges?.large {
                mainBadgeAvenue.prepareItem(at: badgeURL)
                cell.badgeImageView.image = mainBadgeAvenue.item(at: badgeURL)
            }
        }
    }
    
    func configureMatchCell(_ cell: MatchTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        guard let match = team?.matches[indexPath.row] else {
            fault("No team still?")
            return
        }
        matchCellFiller.setup(cell, with: match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
    }
    
    func configureTeamGroupCell(_ cell: TeamGroupTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        guard let groupTeam = team?.group.teams[indexPath.row] else {
            fault("No team, really?")
            return
        }
        teamGroupCellFiller.setup(cell, with: groupTeam, forRowAt: indexPath, afterImageDownload: afterImageDownload)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case groupSectionIndex:
            guard let team = self.team?.group.teams[indexPath.row] else {
                return
            }
            let anotherTeamVC = makeTeamDetailVC(team)
            show(anotherTeamVC, sender: self)
        case matchesSectionIndex:
            guard let match = self.team?.matches[indexPath.row] else {
                return
            }
            let matchVC = makeMatchDetailVC(match)
            show(matchVC, sender: self)
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
            $0.register(UINib.init(nibName: "TeamDetailInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "TeamDetailTeamDetail")
            $0.estimatedRowHeight = 55
            $0.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    fileprivate func configure(smallBadges avenue: SymmetricalAvenue<URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = jprint
    }
    
    fileprivate func configure(mainBadge avenue: SymmetricalAvenue<URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchMainBadge()
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
