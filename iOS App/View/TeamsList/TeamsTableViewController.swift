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

class TeamsTableViewController: TheGreatGame.TableViewController {
    
    var teams: [Team.Compact] = []
    
    var teamsProvider: ReadOnlyCache<Void, [Team.Compact]>!
    var fullTeamProvider: ReadOnlyCache<Team.ID, Team.Full>!
    
    let imageCache = NSCache<NSURL, UIImage>()
    
    var avenue: SymmetricalAvenue<URL, UIImage>!
    
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerFor3DTouch()
        configure(tableView)
        self.avenue = make()
        configure(avenue)
        self.pullToRefreshActivities = make()
        loadTeams()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    fileprivate func loadTeams(onFinish: @escaping () -> () = { }) {
        teamsProvider.retrieve { (teamsResult) in
            assert(Thread.isMainThread)
            onFinish()
            print(teamsResult)
            if let teams = teamsResult.asOptional {
                self.reloadData(with: teams)
            }
        }
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
    
    private func registerFor3DTouch() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    private func make() -> SymmetricalAvenue<URL, UIImage> {
        let imageCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "teams-badges-cache")
        print(imageCache.directoryURL)
        let lane = URLSessionProcessor(session: URLSession(configuration: .ephemeral))
            //.caching(to: imageCache.mapKeys({ $0.path }))
            .connectingNetworkActivityIndicator()
            .mapImage()
            .mapValue({ $0.resized(toFit: CGSize(width: 30, height: 30)) })
        let storage: Storage<URL, UIImage> = NSCacheStorage<NSURL, UIImage>(cache: self.imageCache)
            .mapKey({ $0 as NSURL })
        return Avenue(storage: storage, processor: lane)
    }
    
    private func make() -> NetworkActivity.IndicatorManager {
        return NetworkActivity.IndicatorManager(show: { [weak self] in
            self?.refreshControl?.beginRefreshing()
        }, hide: { [weak self] in
            self?.refreshControl?.endRefreshing()
        })
    }
    
    private func configure(_ avenue: Avenue<URL, URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = {
            print($0)
        }
    }
    
    private func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "TeamCompactTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "TeamCompact")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        pullToRefreshActivities.increment()
        loadTeams {
            self.pullToRefreshActivities.decrement()
        }
    }
    
    func didFetchImage(with url: URL) {
        guard let indexPath = teams.index(where: { $0.badgeURL == url }).map({ IndexPath(row: $0, section: 0) }) else {
            fault("No team with badge url: \(url)")
            return
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            configureCell(cell, forRowAt: indexPath, afterImageDownload: true)
        }
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
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let teamCompact as TeamCompactTableViewCell:
            configureTeamCompactCell(teamCompact, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureTeamCompactCell(_ cell: TeamCompactTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        let team = teams[indexPath.row]
        let badgeURL = team.badgeURL
        if !afterImageDownload {
            avenue.prepareItem(at: badgeURL)
        }
        cell.nameLabel.text = team.name
        cell.shortNameLabel.text = team.shortName
        cell.badgeImageView.setImage(avenue.item(at: badgeURL), afterDownload: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let team = teams[indexPath.row]
//        let detail = Storyboard.Main.teamDetailViewController.instantiate() <- {
//            $0.provider = fullTeamProvider.singleKey(team.id)
//            $0.state = .compact(team)
//            $0.badgeImage = avenue.item(at: team.badgeURL)
//        }
//        navigationController?.pushViewController(detail, animated: true)
        let detail = teamDetailViewController(for: team.id)
        navigationController?.pushViewController(detail, animated: true)
        fullTeamProvider.retrieve(forKey: team.id, completion: jdump)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func teamDetailViewController(for teamID: Team.ID) -> TeamDetailTableViewController {
        return Storyboard.Main.teamDetailTableViewController.instantiate() <- {
            $0.provider = fullTeamProvider.singleKey(teamID)
            $0.imageCache = self.imageCache
        }
    }

}

extension TeamsTableViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        let team = teams[indexPath.row]
        let teamDetail = teamDetailViewController(for: team.id)
        
        let cellRect = tableView.rectForRow(at: indexPath)
        let sourceRect = previewingContext.sourceView.convert(cellRect, from: tableView)
        previewingContext.sourceRect = sourceRect
        
        return teamDetail
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
