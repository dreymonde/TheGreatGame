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
    
    let todayExtension = TodayExtension.shared
    
    var showingMatch: Match.Full?
    
    var avenue: Avenue<URL, UIImage>!
    
    override func viewDidLoad() {
        printWithContext()
        super.viewDidLoad()
        self.avenue = todayExtension.images.makeNotSizedAvenue()
        self.initial()
        self.subscribe()
    }
    
    func subscribe() {
        todayExtension.reactiveRelevantMatches.didUpdate.flatSubscribe(self, with: { vc, matches in vc.setup(with: matches, initial: false) })
    }
    
    func setup(with match: Match.Full, initial: Bool) {
        printWithContext(initial.description)
        self.homeNameLabel.text = match.home.shortName
        self.awayNameLabel.text = match.away.shortName
        self.scoreLabel.text = match.scoreOrPenaltyString()
        if match.isPenaltiesAppointed {
            self.scoreLabel.text?.append(" PEN")
        }
        self.stageTitle.text = TodayViewController.dateFormatter.string(from: match.date)
        avenue.register(homeBadgeImageView, for: match.home.badges.large)
        avenue.register(awayBadgeImageView, for: match.away.badges.large)
        if !initial,
            let _ = avenue.cache.value(forKey: match.home.badges.large),
            let _ = avenue.cache.value(forKey: match.away.badges.large) {
            self.complete(result: .newData)
        }
    }
    
    func setup(with relevantMatches: [Match.Full], initial: Bool) {
        if let mostRelevant = relevantMatches.mostRelevant() {
            self.showingMatch = mostRelevant
            self.setup(with: mostRelevant, initial: initial)
        }
    }
    
    func initial() {
        printWithContext()
        let matches = todayExtension.relevantMatches()
        setup(with: matches, initial: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var _completion: ((NCUpdateResult) -> Void)?
    func complete(result: NCUpdateResult) {
        printWithContext()
        _completion?(result)
        _completion = nil
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        printWithContext()
        // Perform any setup necessary in order to update the view.
        todayExtension.reactiveRelevantMatches.update.fire(errorDelegate: self)
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        self._completion = completionHandler
    }
    
}

extension TodayViewController : ErrorStateDelegate {
    
    func errorDidNotOccur() {
        printWithContext()
    }
    
    func errorDidOccur(_ error: Error) {
        print(error)
        complete(result: .failed)
    }
    
}
