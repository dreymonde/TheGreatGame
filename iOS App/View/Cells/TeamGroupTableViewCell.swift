//
//  TeamGroupTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Avenues
import TheGreatKit

class TeamGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

final class TeamGroupCellFiller : CellFiller {
    
    typealias CellType = TeamGroupTableViewCell
    typealias Content = Group.Team
    
    let avenue: Avenue<URL, UIImage, UIImageView>
    
    init(avenue: Avenue<URL, UIImage, UIImageView>) {
        self.avenue = avenue
    }
    
    func setup(_ cell: TeamGroupTableViewCell, with team: Group.Team, forRowAt indexPath: IndexPath) {
        cell.nameLabel.text = team.name
        cell.pointsLabel.text = String(team.points)
        cell.pointsLabel.textColor = .black
        cell.positionLabel.text = "\(indexPath.row + 1)."
        avenue.register(imageView: cell.badgeImageView, for: team.badges.large)
    }
    
}
