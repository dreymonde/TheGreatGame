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

    // MARK: - Outlets
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: - Data source
    var match: Match.Full?
    
    // MARK: - Injections
    var preloadedMatch: MatchDetailPreLoaded?
    var resource: Resource<Match.Full>!
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject
    var isFavorite: () -> Bool = runtimeInject
    var updateFavorite: (Bool) -> () = runtimeInject
    
    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivityIndicatorManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.avenue = makeAvenue(CGSize(width: 50, height: 50))
        self.pullToRefreshActivities = make()

        configure(tableView)
        configure(navigationItem)
        configure(favoriteButton: favoriteButton)
        
        self.resource.load(confirmation: tableView.reloadData, completion: self.setup(with:source:))
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let favoriteAction = UIPreviewAction(title: isFavorite() ? "Unfavorite" : "Favorite", style: .default) { (action, controller) in
            if let controller = controller as? MatchDetailTableViewController {
                controller.updateFavorite(!controller.isFavorite())
            } else {
                fault("Wrong VC")
            }
        }
        return [favoriteAction]
    }
    
    func setup(with match: Match.Full, source: Source) {
        self.match = match
        self.tableView.reloadData()
        self.configure(navigationItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        resource.reload(connectingToIndicator: pullToRefreshActivities, completion: self.setup(with:source:))
    }

    @IBAction func didPressFavoriteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateFavorite(sender.isSelected)
    }
    
    // MARK: - Table view data source
    
    let matchDetailSection = 0
    let eventsSection = 1

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case matchDetailSection:
            return 1
        case eventsSection:
            return match?.events.count ?? 0
        default:
            fatalError("Undefined section \(section)")
        }
    }
    
    let matchDetailReuseIdentifier = "MatchDetailMatch"
    let matchEventReuseIdentifier = "MatchDetailEvent"

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            switch indexPath.section {
            case matchDetailSection:
                return tableView.dequeueReusableCell(withIdentifier: matchDetailReuseIdentifier, for: indexPath)
            case eventsSection:
                return tableView.dequeueReusableCell(withIdentifier: matchEventReuseIdentifier, for: indexPath)
            default:
                fatalError("Undefined section")
            }
        }()
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let matchDetail as MatchDetailTableViewCell:
            configureMatchDetailCell(matchDetail, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        case let event as MatchEventTableViewCell:
            configureEventCell(event, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault("Such cell is not registered \(type(of: cell))")
        }
    }
    
    func configureMatchDetailCell(_ cell: MatchDetailTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
//        cell.selectionStyle = .none
        if let match = match {
            cell.homeTeamNameLabel.text = match.home.name
            cell.scoreLabel.text = match.scoreString()
            cell.awayTeamLabel.text = match.away.name
        } else if let preloaded = preloadedMatch {
            cell.homeTeamNameLabel.text = preloaded.homeTeamName
            cell.scoreLabel.text = preloaded.score?.demo_string ?? "-:-"
            cell.awayTeamLabel.text = preloaded.awayTeamName
        }
        cell.scoreLabel.textColor = resource.isAbsoluteTruth ? .black : .gray
    }
    
    func configureEventCell(_ cell: MatchEventTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        cell.selectionStyle = .none
        guard let match = match else {
            fault("Match should be existing at this point")
            return
        }
        let eventViewModel = match.events.reversed()[indexPath.row].viewModel(in: match)
        cell.eventTextLabel.text = eventViewModel.text
        cell.eventTitleLabel.text = eventViewModel.title
        cell.minuteLabel.text = eventViewModel.minute
    }

}

extension MatchDetailTableViewController {
    
    // MARK: - Configurations
    
    fileprivate func configure(favoriteButton: UIButton) {
        favoriteButton.isSelected = isFavorite()
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView <- {
            $0.register(UINib.init(nibName: "MatchDetailTableViewCell", bundle: nil), forCellReuseIdentifier: matchDetailReuseIdentifier)
            $0.register(UINib.init(nibName: "MatchEventTableViewCell", bundle: nil), forCellReuseIdentifier: matchEventReuseIdentifier)
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
