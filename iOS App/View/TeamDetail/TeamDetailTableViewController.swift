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

class TeamDetailTableViewController: TheGreatGame.TableViewController {
    
    var team: Team.Full?
    var provider: ReadOnlyCache<Void, Team.Full>!
    var imageCache: NSCache<NSURL, UIImage>!
    
    var avenue: SymmetricalAvenue<URL, UIImage>!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib.init(nibName: "MatchTableViewCell", bundle: nil), forCellReuseIdentifier: "TeamDetailMatch")
        tableView.estimatedRowHeight = 55
        tableView.rowHeight = UITableViewAutomaticDimension
        self.avenue = make()
        configure(avenue)
        provider.retrieve { (result) in
            assert(Thread.isMainThread)
            if let team = result.asOptional {
                self.team = team
                self.tableView.reloadData()
            }
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    private func make() -> SymmetricalAvenue<URL, UIImage> {
        let imageCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "teams-badges-cache")
        print(imageCache.directoryURL)
        let lane = URLSessionProcessor(session: URLSession(configuration: .ephemeral))
            //            .caching(to: imageCache.mapKeys({ $0.path }))
            .connectingNetworkActivityIndicator()
        let storage: Storage<URL, UIImage> = NSCacheStorage<NSURL, UIImage>(cache: self.imageCache)
            .mapKey({ $0 as NSURL })
        return Avenue(storage: storage, processor: lane.mapImage())
    }
    
    private func configure(_ avenue: SymmetricalAvenue<URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = jprint
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    let detailSectionIndex = 0
    let matchesSectionIndex = 1
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case detailSectionIndex:
            return 1
        case matchesSectionIndex:
            return team?.matches.count ?? 0
        default:
            fatalError("What?!")
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
        default:
            configureTeamDetailsCell(cell, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        }
    }
    
    func configureTeamDetailsCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        cell.textLabel?.text = team?.name
        cell.detailTextLabel?.text = team?.shortName
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

}
