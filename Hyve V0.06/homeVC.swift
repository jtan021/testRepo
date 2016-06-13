//
//  FirstViewController.swift
//  Hyve V0.06
//
//  Created by Jonathan Tan on 6/11/16.
//  Copyright © 2016 Jonathan Tan. All rights reserved.
//

import UIKit
import Parse
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func newLocationZoomIn(placemark:MKPlacemark)
}

struct jobMenuItem {
    var menuTitle: String = ""
    var menuImage: UIImage?
}

class homeVC: UIViewController, MKMapViewDelegate , CLLocationManagerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {

    /*
     * Constants
     */
    // MapKit/Location Search
    var geoCoder: CLGeocoder?
    let locationManager = CLLocationManager()
    var previousAddress: String?
    var resultSearchController:UISearchController? = nil
    var searchBar: UISearchBar?
    var selectedPin:MKPlacemark? = nil
    var didStartPanMap:Bool = false
    // Job Menu
    var jobMenuArray = [jobMenuItem]()
    // Request
    var activeTextField: UITextField!
    var viewWasMoved: Bool = false
    var screenRect:CGRect = UIScreen.mainScreen().bounds
    var screenWidth:CGFloat?
    var originY:CGFloat?
    var originX:CGFloat?
   
    /*
     * Outlets
     */
    // MapKit/Location Search
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapMarkerImageView: UIImageView!
    // PostJobButton
    @IBOutlet weak var postJobButton: UIButton!
    // Job Menu
    @IBOutlet weak var jobMenuView: UIView!
    @IBOutlet weak var jobMenuTableView: UITableView!
    // List/Map button
    @IBOutlet weak var switchMapListButton: UIButton!
    @IBOutlet weak var resetMapButton: UIButton!
    // Request view and textfields
    @IBOutlet weak var requestView: UIView!
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var addressTV: UITextView!
    @IBOutlet weak var titleTF: UITextField!
    @IBOutlet weak var categoryTF: UITextField!
    @IBOutlet weak var lifetimeTF: UITextField!
    @IBOutlet weak var descriptionTV: UITextView!
    @IBOutlet weak var descriptionTF: UITextField!
    @IBOutlet weak var offerTF: UITextField!
    @IBOutlet weak var keyTF: UITextField!
    
    /*
     * Action functions
     */
    @IBAction func postJobDidTouch(sender: AnyObject) {
        self.jobMenuView.hidden = false
        print(jobMenuArray.count)
        
        // Replace SearchBar w/ Title
        navigationItem.titleView = nil
        navigationItem.title = "Select a Category"
        
        // Setup Title's font & Color
        var attributes = [
            NSForegroundColorAttributeName: colorWithHexString("E5B924"),
            NSFontAttributeName: UIFont(name: "Avenir Next Demi Bold", size: 22)!
        ]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        
        // Add return button as Right Bar Button
        let buttonImage = UIImage(named: "return")
        let button:UIButton = UIButton(frame: CGRect(x: 0,y: 0,width: 24, height: 24))
        button.setBackgroundImage(buttonImage, forState: .Normal)
        button.addTarget(self, action: Selector("closeJobMenu"), forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @IBAction func resetMapDidTouch(sender: AnyObject) {
        self.resetMapButton.setBackgroundColor(colorWithHexString("E5B924"), forState: UIControlState.Highlighted)
        mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)
    }

    @IBAction func switchMapListButtonDidTouch(sender: AnyObject) {
        self.switchMapListButton.setBackgroundColor(colorWithHexString("E5B924"), forState: UIControlState.Highlighted)
        if(self.switchMapListButton.currentImage == UIImage(named: "list2")) {
            self.switchMapListButton.setImage(UIImage(named: "map2"), forState: UIControlState.Normal)
        } else {
            self.switchMapListButton.setImage(UIImage(named: "list2"), forState: UIControlState.Normal)
        }
    }

    /*
     * Custom functions
     */
    
    func closeJobMenu() -> Void {
        // Remove right bar "return" button
        self.navigationItem.rightBarButtonItem = nil
        // Replace title with Search Bar
        navigationItem.titleView = resultSearchController?.searchBar
        // Hide jobMenuView
        self.jobMenuView.hidden = true
    }
    
    func closeRequestView() -> Void {
        // Remove right bar "return" button
        self.navigationItem.rightBarButtonItem = nil
        // Replace title with Search Bar
        navigationItem.titleView = resultSearchController?.searchBar
        // Hide jobMenuView
        self.requestView.hidden = true
    }
    
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        if (cString.characters.count != 6) {
            return UIColor.grayColor()
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
    
    // Name: locationManager
    // Inputs: None
    // Outputs: None
    // Function: Managers errors with locationManager
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: " + error.localizedDescription)
    }
    
    // Name: locationManager
    // Inputs: None
    // Outputs: None
    // Function: Zooms into map
    func locationManager(manager: CLLocationManager,didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.first!
        self.mapView!.centerCoordinate = location.coordinate
        let reg = MKCoordinateRegionMakeWithDistance(location.coordinate, 1500, 1500)
        self.mapView!.setRegion(reg, animated: true)
        geoCode(location)
    }
    
    // Name: locationManager
    // Inputs: None
    // Outputs: None
    // Function: Obtains coordinates of current location and sends it to be geoCode
    func mapView(mapView: MKMapView, regionDidChangeAnimated animate: Bool) {
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        geoCode(location)
    }
    
    // Name: geoCode
    // Inputs: None
    // Outputs: None
    // Function: reverseGeocodes the current location and updates the searchBar address
    func geoCode(location : CLLocation!) {
        geoCoder!.cancelGeocode()
        geoCoder!.reverseGeocodeLocation(location, completionHandler: { (data, error) -> Void in
            guard let placeMarks = data as [CLPlacemark]! else {
                return
            }
            let loc: CLPlacemark = placeMarks[0]
            let addressDict : [NSString:NSObject] = loc.addressDictionary as! [NSString:NSObject]
            let addrList = addressDict["FormattedAddressLines"] as! [String]
            let address = addrList.joinWithSeparator(", ")
            print(address)
            self.previousAddress = address
            //self.activeUser.currentLocation = address
            self.searchBar!.text = address
        })
    }
    
    // Name: didDismissSearchController
    // Inputs: None
    // Outputs: None
    // Function: If searchController was dismissed, reset address to previously set address
    func didDismissSearchController(searchController: UISearchController) {
        print("Search bar was dismissed.")
        self.searchBar!.text = previousAddress
    }
    
    // Name: gestureRecognizer
    // Inputs: None
    // Outputs: None
    // Function: Returns true if user pans views
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Name: didDragMap
    // Inputs: gestureRecognizer
    // Outputs: None
    // Function: If gestureRecognizer returns true, user is panning the map so hide the postJobButton. If false or panning ends, unhide the postJobButton
    func didDragMap(gestureRecognizer: UIGestureRecognizer) {
        //postJobButton.hidden = true
        if(!self.didStartPanMap) {
            self.postJobButton.hidden = true
            self.mapMarkerImageView.center.y -= 10
            self.didStartPanMap = true
        }
        if gestureRecognizer.state == .Ended {
            //postJobButton.hidden = false
            self.postJobButton.hidden = false
            self.mapMarkerImageView.center.y += 10
            self.didStartPanMap = false
            print("panning ended")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.jobMenuArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuCell = self.jobMenuTableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! jobMenuCell
        menuCell.menuTitle.text = self.jobMenuArray[indexPath.row].menuTitle
        menuCell.menuImage.image = self.jobMenuArray[indexPath.row].menuImage
        
        // Set cell selection color
        var bgColorView: UIView = UIView()
        bgColorView.backgroundColor = colorWithHexString("E5B924")
        menuCell.selectedBackgroundView = bgColorView
        
        return menuCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.requestView.hidden = false
        
        // Add return button as Right Bar Button
        let buttonImage = UIImage(named: "return")
        let button:UIButton = UIButton(frame: CGRect(x: 0,y: 0,width: 24, height: 24))
        button.setBackgroundImage(buttonImage, forState: .Normal)
        button.addTarget(self, action: Selector("closeRequestView"), forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        // Set navigation bar title
        navigationItem.titleView = nil
        navigationItem.title = "Request a Job"
        
        // Hide jobMenuView
        self.jobMenuView.hidden = true
        
        // Set jobMenuView defaults
        self.categoryTF.text = self.jobMenuArray[indexPath.row].menuTitle
        self.offerTF.text = "$0.00"
        self.lifetimeTF.text = "0 Days, 0 Hours, 0 Minutes"
        self.addressTV.text = self.searchBar!.text
    }
    
    //Name: dismissKeyboard
    //Inputs: None
    //Outputs: None
    //Function: Custom function to end text editing for views by dismissing keyboard
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func animateTextField(textField: UITextField, up: Bool) {
        let movementDistance:CGFloat = -130
        let movementDuration: Double = 0.3
        
        var movement:CGFloat = 0
        if up {
            movement = movementDistance
        }
        else {
            movement = -movementDistance
        }
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        UIView.commitAnimations()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if(textField == offerTF || textField == keyTF) {
            self.animateTextField(textField, up:true)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if(textField == offerTF || textField == keyTF) {
            self.animateTextField(textField, up:false)
        }
    }
    
    /*
     * Overrided functions
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set TabBar translucent to false
        self.tabBarController?.tabBar.translucent = false
        
        // Hide jobMenuView & setup jobMenuTableView delegate + datasource
        self.jobMenuView.hidden = true
        self.jobMenuTableView.dataSource = self
        self.jobMenuTableView.delegate = self
        
        // Set request textfield/textview delegates and view to hidden
        self.requestView.hidden = true
        self.titleTF.delegate = self
        self.categoryTF.delegate = self
        self.addressTF.delegate = self
        self.descriptionTF.delegate = self
        self.offerTF.delegate = self
        self.keyTF.delegate = self
        self.lifetimeTF.delegate = self
        self.descriptionTV.delegate = self
        
        // Set request textfield borders
        self.titleTF.borderStyle = .Line
        self.titleTF.layer.borderWidth = 1
        self.titleTF.layer.borderColor = UIColor.grayColor().CGColor
        self.titleTF.layer.cornerRadius = 5
        
        self.categoryTF.borderStyle = .Line
        self.categoryTF.layer.borderWidth = 1
        self.categoryTF.layer.borderColor = UIColor.grayColor().CGColor
        self.categoryTF.layer.cornerRadius = 5
        
        self.addressTF.borderStyle = .Line
        self.addressTF.layer.borderWidth = 1
        self.addressTF.layer.borderColor = UIColor.grayColor().CGColor
        self.addressTF.layer.cornerRadius = 5
        
        self.descriptionTF.borderStyle = .Line
        self.descriptionTF.layer.borderWidth = 1
        self.descriptionTF.layer.borderColor = UIColor.grayColor().CGColor
        self.descriptionTF.layer.cornerRadius = 5
        
        self.offerTF.borderStyle = .Line
        self.offerTF.layer.borderWidth = 1
        self.offerTF.layer.borderColor = UIColor.grayColor().CGColor
        self.offerTF.layer.cornerRadius = 5
        
        self.keyTF.borderStyle = .Line
        self.keyTF.layer.borderWidth = 1
        self.keyTF.layer.borderColor = UIColor.grayColor().CGColor
        self.keyTF.layer.cornerRadius = 5
        
        self.lifetimeTF.borderStyle = .Line
        self.lifetimeTF.layer.borderWidth = 1
        self.lifetimeTF.layer.borderColor = UIColor.grayColor().CGColor
        self.lifetimeTF.layer.cornerRadius = 5
        
        // Load Map
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestLocation()
        geoCoder = CLGeocoder()
        self.mapView!.delegate = self
        
        // Setup location search results table
        let LocationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("locationSearchTable") as! locationSearchTable
        resultSearchController = UISearchController(searchResultsController: LocationSearchTable)
        resultSearchController?.searchResultsUpdater = LocationSearchTable
        resultSearchController?.delegate = self
        
        // Setup search bar and locationSearchTable and link them
        searchBar = resultSearchController!.searchBar
        searchBar!.sizeToFit()
        self.searchBar!.delegate = self
        searchBar!.tintColor = UIColor(white: 0.3, alpha: 1.0)
        self.searchBar!.placeholder = "Enter job location"
        self.searchBar!.text = previousAddress
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        // Search for locations using MKLocalSearchRequest
        LocationSearchTable.mapView = mapView
        LocationSearchTable.handleMapSearchDelegate = self
        
        // Detect if user panned through mapView
        let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "didDragMap:")
        panRecognizer.delegate = self
        self.mapView.addGestureRecognizer(panRecognizer)
        
        // Setup Menu Array
        self.jobMenuArray.removeAll()
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Food delivery", menuImage: UIImage(named:"food")))
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Drink delivery", menuImage: UIImage(named:"drink")))
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Grocery delivery", menuImage: UIImage(named:"grocery")))
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Wait-in-line", menuImage: UIImage(named:"wait")))
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Laundry", menuImage: UIImage(named:"laundry")))
        self.jobMenuArray.append(jobMenuItem(menuTitle: "Special Request", menuImage: UIImage(named:"specialRequest")))
        print(self.jobMenuArray.count)
        
        // Add gesture to close keyboard when tapped outside
        let tapper = UITapGestureRecognizer(target: view, action:#selector(UIView.endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
        
        // Move keyboard up, save view origin
        screenWidth = screenRect.size.width
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension homeVC: HandleMapSearch {
    func newLocationZoomIn(placemark:MKPlacemark){
        selectedPin = placemark
        self.mapView!.centerCoordinate = placemark.coordinate
        let reg = MKCoordinateRegionMakeWithDistance(placemark.coordinate, 1500, 1500)
        self.mapView!.setRegion(reg, animated: true)
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, forState: forState)
    }
}



