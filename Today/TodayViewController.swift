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
    
    static let dateFormatter = DateFormatter() <- {
        $0.timeStyle = .short
        $0.setLocalizedDateFormatFromTemplate("MMMMd" + $0.dateFormat)
    }
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var awayBadgeImageView: UIImageView!

    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var awayNameLabel: UILabel!
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var stageTitle: UILabel!
    
    let todayExtension = TodayExtension()
    
    var showingMatch: Match.Full?
    
    var avenue: SymmetricalAvenue<URL, UIImage>!
    
    var lastConfirmedSource: Source = .memory
        
    override func viewDidLoad() {
        super.viewDidLoad()
        print(homeBadgeImageView.frame.size)
        self.avenue = todayExtension.images.makeNotSizedAvenue()
        avenue.onStateChange = { _ in
            if let match = self.showingMatch {
                self.setup(with: match, afterDownload: true, source: self.lastConfirmedSource)
            }
        }
        avenue.onError = { _,_  in
            self.completion?(.failed)
        }
        // Do any additional setup after loading the view from its nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        update()
    }
    
    func setup(with match: Match.Full, afterDownload: Bool, source: Source) {
        self.homeNameLabel.text = match.home.shortName
        self.awayNameLabel.text = match.away.shortName
        self.scoreLabel.text = match.scoreOrPenaltyString()
        if match.isPenaltiesAppointed {
            self.scoreLabel.text?.append(" PEN")
        }
        self.stageTitle.text = TodayViewController.dateFormatter.string(from: match.date)
        avenue.prepareItem(at: match.home.badges.large)
        avenue.prepareItem(at: match.away.badges.large)
        self.homeBadgeImageView.setImage(avenue.item(at: match.home.badges.large), afterDownload: false)
        self.awayBadgeImageView.setImage(avenue.item(at: match.away.badges.large), afterDownload: false)
        if source.isAbsoluteTruth, let _ = avenue.item(at: match.home.badges.large), let _ = avenue.item(at: match.away.badges.large) {
            self.completion?(.newData)
        }
    }
    
    func update() {
        
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
