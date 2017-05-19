//
//  TeamDetailMatchTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class MatchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var homeTeamNameLabel: UILabel!
    
    @IBOutlet weak var scoreTimeLabel: UILabel! {
        didSet {
            scoreTimeLabel.font = scoreTimeLabel.font.monospacedNumbers()
        }
    }

    @IBOutlet weak var awayTeamNameLabel: UILabel!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
