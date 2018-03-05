//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import WatchKit
import Foundation
import Alba
import TheGreatKit
import Avenues
import Shallows

extension NetworkActivityIndicator {
    
    public convenience init(image: WKInterfaceImage) {
        self.init(show: { 
            image.setHidden(false)
            image.startAnimating()
        }, hide: {
            image.stopAnimating()
            image.setHidden(true)
        })
    }
    
}

let relativeDateFormatter = DateFormatter() <- {
    $0.dateStyle = .medium
    $0.timeStyle = .none
    $0.doesRelativeDateFormatting = true
}

class MatchesInterfaceController: WKInterfaceController {
    
    @IBOutlet var relativeDateLabel: WKInterfaceLabel!
    @IBOutlet var stageLabel: WKInterfaceLabel!
    @IBOutlet var activityImage: WKInterfaceImage!
    @IBOutlet var table: WKInterfaceTable!
    
    let matchRowType = "MatchCompact"
    
    struct Context {
        let matches: [Match.Full]
        let reactive: Reactive<[Match.Full]>
        let makeAvenue: (CGSize) -> Avenue<URL, UIImage>
    }
    
    var context: Context!
    var avenue: Avenue<URL, UIImage>!
    var networkActivityIndicator: NetworkActivityIndicator!
    
    var matches: [Match.Full] = [] {
        didSet {
            stageLabel.setText(matches.first?.stageTitle)
            relativeDateLabel.setText(matches.first.map({ relativeDateFormatter.string(from: $0.date) }))
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.context = ExtensionDelegate.userInterface.makeContext(for: MatchesInterfaceController.self)
        self.networkActivityIndicator = NetworkActivityIndicator(image: activityImage)
        self.avenue = self.context.makeAvenue(CGSize.init(width: 35, height: 35))
            .connectingNetworkActivityIndicator(manager: networkActivityIndicator)
        printWithContext()
        self.matches = self.context.matches
        subscribe()
        self.context.reactive.update.fire(activityIndicator: networkActivityIndicator,
                                          errorDelegate: UnimplementedErrorStateDelegate.shared)
    }
    
    func subscribe() {
        context.reactive.didUpdate.subscribe(self, with: MatchesInterfaceController.reload)
    }
    
    func reload(with matches: [Match.Full]) {
        printWithContext()
        self.matches = matches
        table.setNumberOfRows(matches.count, withRowType: matchRowType)
        for (match, index) in zip(matches, matches.indices) {
            let controller = table.rowController(at: index) as! MatchCellController
            configure(controller, with: match, forRowAt: index)
        }
    }
    
    func configure(_ cell: MatchCellController, with match: Match.Full, forRowAt index: Int) {
        avenue.register(cell.homeBadgeImage, for: match.home.badges.large)
        avenue.register(cell.awayBadgeImage, for: match.away.badges.large)
        cell.scoreLabel.setText(match.scoreOrTimeString())
        if match.score == nil {
            cell.scoreLabel.setTextColor(.lightGray)
        } else {
            cell.scoreLabel.setTextColor(.white)
        }
        configureProgressSeparator(cell.minutesPassedSeparator, with: match)
    }
    
    func configureProgressSeparator(_ separator: WKInterfaceSeparator, with match: Match.Full) {
        if match.isEnded {
            separator.setRelativeWidth(1.0, withAdjustment: 0)
            let finishedColor = UIColor(red: 46 / 255, green: 204 / 255, blue: 113 / 255, alpha: 1.0)
            separator.setColor(finishedColor)
        } else if !match.isStarted {
            separator.setRelativeWidth(0.0, withAdjustment: 0)
        } else {
            separator.setRelativeWidth(CGFloat(match.progress()), withAdjustment: 0)
            let inProcessColor = UIColor(red: 52 / 255, green: 152 / 255, blue: 219 / 255, alpha: 1.0)
            separator.setColor(inProcessColor)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
