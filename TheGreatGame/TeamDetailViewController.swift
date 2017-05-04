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

class TeamDetailViewController: TheGreatGame.ViewController {
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
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
        setup()
        loadTeam()
        // Do any additional setup after loading the view.
    }
    
    private func setup() {
        switch state {
        case .compact(let compact):
            self.navigationItem.title = compact.name
            badgeImageView.image = badgeImage
        case .full(let full):
            descriptionLabel.text = full.description
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
