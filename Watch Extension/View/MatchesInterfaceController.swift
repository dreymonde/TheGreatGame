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

class MatchesInterfaceController: WKInterfaceController {
    
    @IBOutlet var table: WKInterfaceTable!
    let matchRowType = "MatchCompact"
    
    struct Context {
        let resource: Resource<[Match.Compact]>
        let makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage>
    }
    
    var context: Context!
    var avenue: Avenue<URL, URL, UIImage>!
    
    var matches: [Match.Compact] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.context = ExtensionDelegate.userInterface.makeContext(for: MatchesInterfaceController.self)
        self.avenue = self.context.makeAvenue(CGSize.init(width: 25, height: 25))
        printWithContext()
        configure(avenue)
        self.context.resource.load(completion: reload(with:source:))
    }
    
    private func configure(_ avenue: SymmetricalAvenue<URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            self?.didFetchImage(with: url)
        }
    }
    
    func didFetchImage(with url: URL) {
        for (match, index) in zip(matches, matches.indices) {
            if match.teams.map({ $0.badgeURL }).contains(url) {
                let controller = table.rowController(at: index) as! MatchCellController
                print("Setting image!")
                configure(controller, with: match, forRowAt: index)
            }
        }
    }
    
    func reload(with matches: [Match.Compact], source: Source) {
        self.matches = matches
        table.setNumberOfRows(matches.count, withRowType: matchRowType)
        for (match, index) in zip(matches, matches.indices) {
            let controller = table.rowController(at: index) as! MatchCellController
            configure(controller, with: match, forRowAt: index)
        }
    }
    
    func configure(_ cell: MatchCellController, with match: Match.Compact, forRowAt index: Int) {
        avenue.prepareItem(at: match.home.badgeURL)
        avenue.prepareItem(at: match.away.badgeURL)
        cell.scoreLabel.setText(match.score?.demo_string ?? "-:-")
        cell.homeBadgeImage.setImage(avenue.item(at: match.home.badgeURL))
        cell.awayBadgeImage.setImage(avenue.item(at: match.away.badgeURL))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
