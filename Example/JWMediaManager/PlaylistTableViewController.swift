//
//  PlaylistTableViewController.swift
//  JWMediaManager
//
//  Created by Jianxiong Wang on 2/19/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class PlaylistTableViewController: UITableViewController {
    
    var playlist:[URL]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = playlist[indexPath.row].lastPathComponent

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (self.navigationController?.viewControllers[0] as? ViewController)?.selectedIndex = indexPath.row
        _ = self.navigationController?.popViewController(animated: true)
    }
}
