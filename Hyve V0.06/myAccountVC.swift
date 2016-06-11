//
//  SecondViewController.swift
//  Hyve V0.06
//
//  Created by Jonathan Tan on 6/11/16.
//  Copyright © 2016 Jonathan Tan. All rights reserved.
//

import UIKit
import Parse

struct menuItem {
    var title:String = ""
    var cell:String = ""
    var image:UIImage?
}

class myAccountVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /*
     * Constants
     */
    var accountMenuArray = [menuItem]()
    
    /*
     * Outlets
     */
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var profileFullName: UILabel!
    @IBOutlet weak var profileUsername: UILabel!
    @IBOutlet weak var profileWallet: UILabel!
    @IBOutlet weak var accountMenuTableView: UITableView!
    
    /*
     * Action functions
     */
    
    /*
     * Custom functions
     */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accountMenuArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuCell = self.accountMenuTableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! accountMenuCell
        menuCell.menuTitle.text = self.accountMenuArray[indexPath.row].title
        menuCell.menuImage.image = self.accountMenuArray[indexPath.row].image
        return menuCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(self.accountMenuArray[indexPath.row].cell == "logOutCell") {
            PFUser.logOut()
            let currentUser = PFUser.currentUser()
            if(currentUser?.username == nil) {
                print("\nLogout Successful\n")
                self.performSegueWithIdentifier("successfulLogOutSegue", sender: self)
            }
        }
    }
    
    /*
     * Overrided functions
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set tableView delegate and datasource
        self.accountMenuTableView.delegate = self
        self.accountMenuTableView.dataSource = self
        
        // Fill up the menu array
        self.accountMenuArray.removeAll()
        self.accountMenuArray.append(menuItem(title: "Logout", cell: "logOutCell", image: UIImage(named: "logOut")))
        print(accountMenuArray.count)
        self.accountMenuTableView.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

