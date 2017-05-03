//
//  TeamCompactTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class TeamCompactTableViewCell: UITableViewCell {
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var shortNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setBadge(_ badgeImage: UIImage?, afterImageDownload: Bool) {
        let old = badgeImageView.image
        badgeImageView.image = badgeImage
        if afterImageDownload && badgeImage != nil && old == nil {
            let transition = CATransition() <- {
                $0.duration = 0.2
                $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                $0.type = kCATransitionFade
            }
            badgeImageView.layer.add(transition, forKey: nil)
        }
    }
    
}
