//
//  TeamDetailInfoTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 09.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class TeamDetailInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var teamSummaryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
