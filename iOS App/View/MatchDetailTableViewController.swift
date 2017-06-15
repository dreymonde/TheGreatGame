//
//  MatchDetailTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

struct MatchDetailPreLoaded {
    
    let homeTeamName: String?
    let homeTeamShortName: String?
    let score: Match.Score?
    let awayTeamName: String?
    let awayTeamShortName: String?
    
}

extension MatchProtocol {
    
    func preloaded() -> MatchDetailPreLoaded {
        return MatchDetailPreLoaded(homeTeamName: home.name, homeTeamShortName: home.shortName, score: score, awayTeamName: away.name, awayTeamShortName: away.shortName)
    }
    
}

class MatchDetailTableViewController: TableViewController, Refreshing {
    
    // MARK: - Data source
    var match: Match.Full?
    
    // MARK: - Injections
    var preloadedMatch: MatchDetailPreLoaded?
    var resource: Resource<Match.Full>!
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject
    
    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivityIndicatorManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.avenue = makeAvenue(CGSize(width: 50, height: 50))
        self.pullToRefreshActivities = make()

        configure(tableView)
        configure(navigationItem)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchDetailMatch", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let matchDetail as MatchDetailTableViewCell:
            configureMatchDetailCell(matchDetail, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault("Such cell is not registered \(type(of: cell))")
        }
    }
    
    func configureMatchDetailCell(_ cell: MatchDetailTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        cell.selectionStyle = .none
        if let match = match {
            later
        } else if let preloaded = preloadedMatch {
            cell.homeTeamNameLabel.text = preloaded.homeTeamName
            cell.scoreLabel.text = preloaded.score?.demo_string ?? "-:-"
            cell.awayTeamLabel.text = preloaded.awayTeamName
        }
    }

}

extension MatchDetailTableViewController {
    
    // MARK: - Configurations
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView <- {
            $0.register(UINib.init(nibName: "MatchDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "MatchDetailMatch")
            $0.estimatedRowHeight = 70
            $0.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    fileprivate func configure(_ navigationItem: UINavigationItem) {
        navigationItem.title = match?.title ?? preloadedMatch?.title
    }
    
}

extension MatchProtocol {
    
    fileprivate var title: String {
        return "\(home.shortName) : \(away.shortName)"
    }
    
}

extension MatchDetailPreLoaded {
    
    fileprivate var title: String {
        return "\(homeTeamShortName ?? "") : \(awayTeamShortName ?? "")"
    }
    
}
