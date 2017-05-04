//
//  TeamsTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

class TeamsTableViewController: UITableViewController {
    
    var teams: [Team] = []
    
    var provider: ReadOnlyCache<Void, [Team]>!
    let avenue: Avenue<IndexPath, URL, UIImage> = {
        let imageCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "teams-badges-cache")
        print(imageCache.directoryURL)
        let lane = URLSessionProcessor(session: URLSession(configuration: .ephemeral))
            //.caching(to: imageCache.mapKeys({ $0.path }))
            .connectingNetworkActivityIndicator()
        let storage: Storage<IndexPath, UIImage> = NSCacheStorage<NSIndexPath, UIImage>()
            .mapKey({ $0 as NSIndexPath })
        return Avenue(storage: storage, processor: lane.mapImage())
    }()
    
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(tableView)
        configure(avenue)
        self.pullToRefreshActivities = make()
        loadTeams()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    fileprivate func loadTeams(onFinish: @escaping () -> () = { }) {
        provider.retrieve { (teamsResult) in
            assert(Thread.isMainThread)
            onFinish()
            print(teamsResult)
            if let teams = teamsResult.asOptional {
                self.teams = teams
                self.tableView.reloadData()
            }
        }
    }
    
    private func make() -> NetworkActivity.IndicatorManager {
        return NetworkActivity.IndicatorManager(show: { [weak self] in
            self?.refreshControl?.beginRefreshing()
        }, hide: { [weak self] in
            self?.refreshControl?.endRefreshing()
        })
    }
    
    private func configure(_ avenue: Avenue<IndexPath, URL, UIImage>) {
        avenue.onStateChange = { [weak self] indexPath in
            assert(Thread.isMainThread)
            self?.didFetchImage(at: indexPath)
        }
        avenue.onError = {
            print($0)
        }
    }
    
    private func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "TeamCompactTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "TeamCompact")
        tableView.rowHeight = 50
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        pullToRefreshActivities.increment()
        loadTeams {
            self.pullToRefreshActivities.decrement()
        }
    }
    
    func didFetchImage(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            configureCell(cell, forRowAt: indexPath, afterImageDownload: true)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCompact", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let teamCompact as TeamCompactTableViewCell:
            configureTeamCompactCell(teamCompact, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureTeamCompactCell(_ cell: TeamCompactTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        let team = teams[indexPath.row]
        if !afterImageDownload {
            avenue.prepareItem(for: team.badgeURL, storingTo: indexPath)
        }
        cell.nameLabel.text = team.name
        cell.shortNameLabel.text = team.shortName
        cell.setBadge(avenue.item(at: indexPath), afterImageDownload: afterImageDownload)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
