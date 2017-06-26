//
//  MatchDetailTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class MatchDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var homeTeamNameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var awayTeamLabel: UILabel!

    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var homeFlagImageView: UIImageView!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    @IBOutlet weak var awayFlagImageView: UIImageView!
    
    @IBOutlet weak var stageTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
