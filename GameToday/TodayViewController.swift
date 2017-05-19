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

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var label: UILabel!
    
    let todayExtension = TodayExtension()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let allMatches = todayExtension.api.matches.all
        let favorites = todayExtension.favoriteTeams.favoriteTeams
        let zipped = zip(allMatches, favorites)
        zipped.mainThread().retrieve { (result) in
            if let retrieved = result.asOptional {
                let matches = retrieved.0.content.matches
                let favorites = retrieved.1
                print(favorites)
                let favoriteMatches = matches.filter({ !Set($0.teams.map({ $0.id })).intersection(favorites).isEmpty })
                print(favoriteMatches)
                if let mostRelevant = favoriteMatches.mostRelevant() {
                    self.label.text = "\(mostRelevant.home.name) : \(mostRelevant.away.name)"
                } else {
                    self.label.text = "-:-"
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
