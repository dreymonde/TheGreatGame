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
    @IBOutlet weak var favoriteButton: UIButton! {
        didSet {
            favoriteButton.tintColor = UIColor(named: .navigationBackground)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
        
    @IBAction func buttonDidTouchUpInside(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        onSwitch(sender.isSelected)
    }
    
    var onSwitch: (Bool) -> () = { _ in }
        
}
