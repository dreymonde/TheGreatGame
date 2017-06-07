//
//  TodayViewController.swift
//  GameToday
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import NotificationCenter
import Shallows
import Avenues
import TheGreatKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var awayNameLabel: UILabel!
    
    let todayExtension = TodayExtension()
    
    var showingMatch: Match.Compact?
    
    var avenue: SymmetricalAvenue<URL, UIImage>!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.avenue = todayExtension.images.makeAvenue(forImageSize: homeBadgeImageView.frame.size)
        avenue.onStateChange = { _ in
            if let match = self.showingMatch {
                self.setup(with: match, afterDownload: true)
            }
        }
        avenue.onError = { _ in
            self.completion?(.failed)
        }
        // Do any additional setup after loading the view from its nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        update()
    }
    
    func setup(with match: Match.Compact, afterDownload: Bool) {
        self.homeNameLabel.text = match.home.shortName
        self.awayNameLabel.text = match.away.shortName
        avenue.prepareItem(at: match.home.badgeURL)
        avenue.prepareItem(at: match.away.badgeURL)
        self.homeBadgeImageView.setImage(avenue.item(at: match.home.badgeURL), afterDownload: false)
        self.awayBadgeImageView.setImage(avenue.item(at: match.away.badgeURL), afterDownload: false)
        if let _ = avenue.item(at: match.home.badgeURL), let _ = avenue.item(at: match.away.badgeURL) {
            self.completion?(.newData)
        }
    }
    
    func update() {
        let allMatches = todayExtension.api.matches.all
        let cachedAllMatches = todayExtension.cachier.cachedLocally(allMatches, key: "all-matches", token: "all-matches")
        let favorites = todayExtension.favoriteTeams.favoriteTeams
        let zipped = zip(cachedAllMatches, favorites)
        zipped.mainThread().retrieve { (result) in
            if let retrieved = result.value {
                let matches = retrieved.0.lastRelevant.matches
                let favorites = retrieved.1
                print(favorites)
                let favoriteMatches = matches.filter({ !Set($0.teams.map({ $0.id })).intersection(favorites).isEmpty })
                if let mostRelevant = favoriteMatches.mostRelevant() {
                    self.showingMatch = mostRelevant
                    self.setup(with: mostRelevant, afterDownload: false)
                }
            } else {
                self.completion?(.failed)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var completion: ((NCUpdateResult) -> Void)?
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        self.completion = completionHandler
    }
    
}
