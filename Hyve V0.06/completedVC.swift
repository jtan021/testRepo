//
//  completedVC.swift
//  Hyve V0.06
//
//  Created by Jonathan Tan on 6/11/16.
//  Copyright © 2016 Jonathan Tan. All rights reserved.
//

import UIKit

class completedVC: UIViewController {
    /*
     * Constants
     */
    
    /*
     * Outlets
     */
    
    /*
     * Action functions
     */
    
    /*
     * Custom functions
     */
    
    /*
     * Overrided functions
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set TabBar translucent to false
        self.tabBarController?.tabBar.translucent = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
