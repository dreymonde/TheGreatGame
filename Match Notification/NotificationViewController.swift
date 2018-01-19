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
        avenue.onStateChange = { [weak self] _ in
            self?.reload(afterImageDownload: true)
        }
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let push = PushNotification<Match.Full>(userInfo: notification.request.content.userInfo) else {
            fault("Push is not match")
            return
        }
        let match = push.content
        self.match = match
        reload(afterImageDownload: false)
    }
    
    func reload(afterImageDownload: Bool) {
        guard let match = match else {
            fault("No match in reload")
            return
        }
        avenue.prepareItem(at: match.home.badges.large)
        avenue.prepareItem(at: match.away.badges.large)
        scoreLabel.text = match.scoreOrPenaltyString()
        homeLabel.text = match.home.shortName
        awayLabel.text = match.away.shortName
//        if let lastEvent = match.events.last {
//            let vm = lastEvent.viewModel(in: match)
////            eventLabel.text = vm.text
////            minuteLabel.text = vm.minute
//        }
        homeBadgeImageView.setImage(avenue.item(at: match.home.badges.large), afterDownload: afterImageDownload)
        awayBadgeImageView.setImage(avenue.item(at: match.away.badges.large), afterDownload: afterImageDownload)
    }
    
}
