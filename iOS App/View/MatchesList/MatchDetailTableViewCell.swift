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
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    
    @IBOutlet weak var penaltyLabel: UILabel!
    
    var onHomeBadgeTap: () -> () = { }
    
    @objc func didTapHomeBadge(_ sender: UITapGestureRecognizer) {
        onHomeBadgeTap()
    }
    
    var onAwayBadgeTap: () -> () = { }
    
    @objc func didTapAwayBadge(_ sender: UITapGestureRecognizer) {
        onAwayBadgeTap()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let homeBadgeGesture = UITapGestureRecognizer(target: self, action: #selector(didTapHomeBadge(_:)))
        homeBadgeImageView.addGestureRecognizer(homeBadgeGesture)
        
        let awayBadgeGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAwayBadge(_:)))
        awayBadgeImageView.addGestureRecognizer(awayBadgeGesture)
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
