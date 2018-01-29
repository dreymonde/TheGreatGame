//
//  MatchEventTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class MatchEventTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var stackView: UIStackView!
    
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTextLabel: UILabel!
    
    func setText(_ text: String?, on label: UILabel) {
        if let text = text, !text.isEmpty {
            label.text = text
            label.isHidden = false
        } else {
            label.text = nil
            label.isHidden = true
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
    
}
