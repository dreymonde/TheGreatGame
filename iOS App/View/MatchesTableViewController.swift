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

class MatchesTableViewController: TheGreatGame.TableViewController {
    
    var matches: [Match.Compact] = []
    
    var matchesProvider: ReadOnlyCache<Void, [Match.Compact]>!
    
    var avenue: SymmetricalAvenue<URL, UIImage>!
    
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(tableView)
        self.avenue = make()
        configure(avenue)
        self.pullToRefreshActivities = make()
        loadMatches()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    fileprivate func loadMatches(onFinish: @escaping () -> () = { }) {
        matchesProvider.retrieve { (teamsResult) in
            assert(Thread.isMainThread)
            onFinish()
            print(teamsResult)
            if let teams = teamsResult.asOptional {
                self.reloadData(with: teams)
            }
        }
    }
    
    fileprivate func reloadData(with matches: [Match.Compact]) {
        if self.matches.isEmpty {
            self.matches = matches
            let ips = matches.indices.map({ IndexPath.init(row: $0, section: 0) })
            tableView.insertRows(at: ips, with: UITableViewRowAnimation.automatic)
        } else {
            self.matches = matches
            tableView.reloadData()
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
        let storage: Storage<URL, UIImage> = NSCacheStorage<NSURL, UIImage>()
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
        tableView.register(UINib.init(nibName: "MatchTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "MatchListMatch")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        pullToRefreshActivities.increment()
        loadMatches {
            self.pullToRefreshActivities.decrement()
        }
    }
    
    func didFetchImage(with url: URL) {
        var paths: [IndexPath] = []
        for (match, index) in zip(matches, matches.indices) {
            if match.teams.map({ $0.badgeURL }).contains(url) {
                paths.append(IndexPath.init(row: index, section: 0))
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchListMatch", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let match as MatchTableViewCell:
            configureMatchCell(match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureMatchCell(_ cell: MatchTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        let match = matches[indexPath.row]
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}
