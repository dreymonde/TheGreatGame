//
//  MatchEventTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit

class MatchEventTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTextLabel: UILabel!
    
    func setText(_ text: String?, on label: UILabel) {
        if let text = text, text.characters.count != 0 {
            label.text = text
            stackView.addArrangedSubview(label)
        } else {
            label.text = nil
            stackView.removeArrangedSubview(label)
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
