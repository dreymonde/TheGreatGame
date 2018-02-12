//
//  NotificationViewController.swift
//  Notification
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import TheGreatKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var homeLabel: UILabel!
    @IBOutlet weak var awayLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    
    let avenue = Images.inContainer(.shared).makeAvenue(forImageSize: CGSize.init(width: 100, height: 100), activityIndicator: .none)
    
    var match: Match.Full?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let match = try? PushNotification(notification.request.content).extract(Match.Full.self) else {
            fault("Push is not match")
            return
        }
        self.match = match
        reload()
    }
    
    func reload() {
        guard let match = match else {
            fault("No match in reload")
            return
        }
        avenue.register(homeBadgeImageView, for: match.home.badges.large)
        avenue.register(awayBadgeImageView, for: match.away.badges.large)
        scoreLabel.text = match.scoreOrPenaltyString()
        homeLabel.text = match.home.shortName
        awayLabel.text = match.away.shortName
//        if let lastEvent = match.events.last {
//            let vm = lastEvent.viewModel(in: match)
////            eventLabel.text = vm.text
////            minuteLabel.text = vm.minute
//        }
    }
    
}
