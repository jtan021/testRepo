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

class homeVC: UIViewController, MKMapViewDelegate , CLLocationManagerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

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
    var categoryPicker = UIPickerView()
    var datePicker = UIPickerView()
    var screenWidth:CGFloat?
    var screenRect:CGRect = UIScreen.mainScreen().bounds
    var day:Int = 0
    var hour: Int = 0
    var minute: Int = 0
    var hourArray = [AnyObject]()
    var minuteArray = [AnyObject]()
    var dayArray = [AnyObject]()
    var pickerStringVal: String = String()
    var PLACEHOLDER_TEXT = "This is optional but if you want to, tell us more about your request! Any specifics?"
    
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
        let movementDistance:CGFloat = -150
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
    
    // Name: numberOfComponentsInPickerView
    // Inputs: None
    // Outputs: None
    // Function: Sets the number of components in the pickerview
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if(pickerView == datePicker) {
            return 6
        } else {
            return 1
        }
    }
    
    // Name: pickerView
    // Inputs: None
    // Outputs: None
    // Function: Sets variables: day, hour, minute, and updates the jobLifeTextField with user selection
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == self.datePicker) {
            switch component {
            case 0:
                self.day = row
            case 2:
                self.hour = row
            case 4:
                self.minute = row
            default:
                print("No component with number \(component)")
            }
            if (day > 1) {
                lifetimeTF.text = "\(day) Days"
            } else {
                lifetimeTF.text = "\(day) Day"
            }
            
            if (hour > 1) {
                lifetimeTF.text = "\(lifetimeTF.text!), \(hour) Hours"
            } else {
                lifetimeTF.text = "\(lifetimeTF.text!), \(hour) Hour"
            }
            
            if (minute > 1) {
                lifetimeTF.text = "\(lifetimeTF.text!), \(minute) Minutes."
            } else {
                lifetimeTF.text = "\(lifetimeTF.text!), \(minute) Minute."
            }
        } else if(pickerView == self.categoryPicker) {
            categoryTF.text = self.jobMenuArray[row].menuTitle
        }
    }
    
    // Name: pickerView
    // Inputs: None
    // Outputs: None
    // Function: Sets the number of choices in each component of the pickerView
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == self.datePicker) {
            if component == 0 {
                return dayArray.count
            } else if component == 2 {
                return hourArray.count
            } else if component == 4 {
                return minuteArray.count
            } else {
                return 1
            }
        } else if (pickerView == self.categoryPicker) {
            return jobMenuArray.count
        } else {
            return 1
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title: String? = nil
        if(pickerView == self.categoryPicker) {
            return jobMenuArray[row].menuTitle
        } else {
            return "\(row)"
        }
    }
    
    // Name: pickerView
    // Inputs: None
    // Outputs: None
    // Function: Populates the keyboard pickerViews with required fields.
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        if pickerView == datePicker {
            let columnView = UILabel(frame: CGRectMake(30, 0, screenWidth!/6 - 30, 30))
            if(component == 1) {
                columnView.text = "Day"
            } else if(component == 3) {
                columnView.text = "Hour"
            } else if(component == 5) {
                columnView.text = "Min"
            } else {
                columnView.text = "\(row)"
                columnView.textAlignment = NSTextAlignment.Center
            }
            return columnView
        } else if pickerView == categoryPicker {
            let columnView = UILabel(frame: CGRectMake(30, 0, screenWidth! - 30, 30))
            columnView.text = self.jobMenuArray[row].menuTitle
            columnView.textAlignment = NSTextAlignment.Center
            return columnView
        }
        return view
    }
    
    // Name: textFieldDidChange
    // Inputs: None
    // Outputs: None
    // Function: Adds a '$' to the front of the jobOfferTextField if user inputs text
    func textFieldDidChange(textField: UITextField) {
        if !(self.offerTF.text!.hasPrefix("$")) {
            self.offerTF.text = "$\(self.offerTF.text!)"
        } else {
            if (self.offerTF.text!.hasSuffix("$")) {
                self.offerTF.text = ""
            }
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string) as? NSString
        var arrayOfString: [AnyObject] = newString!.componentsSeparatedByString(".")
        // Check if there are more than 1 decimal points
        if arrayOfString.count > 2 {
            return false
        }
        // Check for more than 2 chars after the decimal point
        if (arrayOfString.count > 1)
        {
            let decimalAmount:NSString = arrayOfString[1] as! String
            if(decimalAmount.length > 2) {
                return false
            }
        }
        // Check for an absurdly large amount
        if (arrayOfString.count > 0)
        {
            let dollarAmount:NSString = arrayOfString[0] as! String
            if (dollarAmount.length > 6) {
                return false
            }
        }
        return true
    }
    
//      Un-comment to enable placeholder text for textView
//      Name: textViewDidBeginEditing
//      Inputs: None
//      Outputs: None
//      Function: If user edits textView, check textColor to make sure it is returned to blackColor
     func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
     }
     
//      Name: textViewDidChange
//      Inputs: None
//      Outputs: None
//      Function: If textView is changed, check if empty. If it is empty, update it with placeholder text
     func textViewDidChange(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = PLACEHOLDER_TEXT
        }
     }
     
//      Name: textViewDidChange
//      Inputs: None
//      Outputs: None
//      Function: If user finished editing the textView, check if empty. If it is empty, update it with placeholder text
     func textViewDidEndEditing(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = PLACEHOLDER_TEXT
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
        
        // Create UIPickerView for lifetimeTF Input
        datePicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 280))
        datePicker.backgroundColor = .whiteColor()
        datePicker.showsSelectionIndicator = true
        self.datePicker.dataSource = self
        self.datePicker.delegate = self
        self.screenWidth = screenRect.size.width
        
        // Create UIPickerView for categoryTF Input
        //categoryPicker = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 280))
        categoryPicker.backgroundColor = .whiteColor()
        categoryPicker.showsSelectionIndicator = true
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        
        // Populate day/hour/min array
        for i in 0...59 {
            pickerStringVal = "\(i)"
            //Creates day array with 0-13 days
            if (i < 14) {
                dayArray.append(pickerStringVal)
                //Creates hour array with 0-23 hours
            }
            if (i < 24) {
                hourArray.append(pickerStringVal)
                //Creates minute array with 0-59 minutes
            }
            minuteArray.append(pickerStringVal)
        }
        
        // Create a "Done" button to add the the UIPickerView
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        toolBar.setBackgroundImage(UIImage(named: "Hyve_BG2"), forToolbarPosition: .Any, barMetrics: .Default)
        toolBar.translucent = false
        toolBar.tintColor = colorWithHexString("E5B924")
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Bordered, target: self, action: "dismissKeyboard:")
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.userInteractionEnabled = true
        
        // Set lifetimeTF keyboard input to be the pickerView and add done button
        self.lifetimeTF.inputView = datePicker
        self.categoryTF.inputView = categoryPicker

        // Set offerTF keyboard to numberpad and edit string if offerTF is edited
        self.offerTF.keyboardType = UIKeyboardType.DecimalPad
        self.offerTF.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        // Add done button to all text keyboards
        self.titleTF.inputAccessoryView = toolBar
        self.categoryTF.inputAccessoryView = toolBar
        self.offerTF.inputAccessoryView = toolBar
        self.keyTF.inputAccessoryView = toolBar
        self.lifetimeTF.inputAccessoryView = toolBar
        self.descriptionTV.inputAccessoryView = toolBar
        
        // Add placeholder to textview
        self.descriptionTV.text = PLACEHOLDER_TEXT
        self.descriptionTV.textColor = UIColor.lightGrayColor()
        
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

extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}



