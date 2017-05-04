//
//  TeamDetailViewController.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows

class TeamDetailViewController: TheGreatGame.TableViewController {
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    
    enum State {
        case compact(Team.Compact)
        case full(Team.Full)
        case undefined
    }
    
    var state: State = .undefined
    var badgeImage: UIImage?
    
    var provider: ReadOnlyCache<Void, Team.Full>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .groupTableViewBackground
        setup()
        loadTeam()
        // Do any additional setup after loading the view.
    }
    
    private func setup() {
        switch state {
        case .compact(let compact):
            self.navigationItem.title = compact.name
            badgeImageView.image = badgeImage
            flagImageView.image = badgeImage
            nameLabel.text = compact.name
            codeLabel.text = compact.shortName
            rankLabel.text = String(compact.rank)
        case .full:
            break
        case .undefined:
            fault("State should be initialized")
        }
    }
    
    private func loadTeam() {
        provider.retrieve { (result) in
            if let team = result.asOptional {
                self.state = .full(team)
                self.setup()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
