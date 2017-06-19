//
//  TeamDetailMatchTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Avenues
import TheGreatKit

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

final class MatchCellFiller : CellFiller {
    
    typealias CellType = MatchTableViewCell
    typealias Content = Match.Compact
    
    let avenue: Avenue<URL, URL, UIImage>
    let isFavorite: (Match.Compact) -> Bool
    let isAbsoluteTruth: () -> Bool
    
    init(avenue: Avenue<URL, URL, UIImage>, isFavorite: @escaping (Match.Compact) -> Bool, isAbsoluteTruth: @escaping () -> Bool) {
        self.avenue = avenue
        self.isFavorite = isFavorite
        self.isAbsoluteTruth = isAbsoluteTruth
    }
    
    func setup(_ cell: MatchTableViewCell, with match: Match.Compact, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        if !afterImageDownload {
            avenue.prepareItem(at: match.home.badges.large)
            avenue.prepareItem(at: match.away.badges.large)
        }
        if isFavorite(match) {
            cell.backgroundColor = UIColor(named: .favoriteBackground)
        } else {
            cell.backgroundColor = .white
        }
        if isAbsoluteTruth() {
            cell.scoreTimeLabel.textColor = .black
        } else {
            cell.scoreTimeLabel.textColor = .gray
        }
        cell.scoreTimeLabel.text = match.score?.string ?? "-:-"
        cell.homeTeamNameLabel.text = match.home.name
        cell.awayTeamNameLabel.text = match.away.name
        cell.homeBadgeImageView.setImage(avenue.item(at: match.home.badges.large), afterDownload: afterImageDownload)
        cell.awayBadgeImageView.setImage(avenue.item(at: match.away.badges.large), afterDownload: afterImageDownload)
    }
    
}

