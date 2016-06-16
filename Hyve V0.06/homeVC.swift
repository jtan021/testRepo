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
    // THLabel Constants
    var kShadowColor1 = UIColor.blackColor
    var kShadowColor2 = UIColor(white: 0.0, alpha: 0.75)
    var kShadowOffset = CGSizeMake(0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 4.0 : 2.0)
    var kShadowBlur:CGFloat = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 10.0 : 5.0)
    var kInnerShadowOffset = CGSizeMake(0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 2.0 : 1.0)
    var kInnerShadowBlur:CGFloat = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 4.0 : 2.0)
    var kStrokeColor = UIColor.blackColor()
    var kStrokeSize:CGFloat = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad ? 4.0 : 2.0)
    var kGradientStartColor = UIColor(colorLiteralRed: 229/255, green: 185/255, blue: 36/255, alpha: 1.0)
    var kGradientEndColor = UIColor(colorLiteralRed: 255/255, green: 138/255, blue: 0/255, alpha: 1.0)
    // Search stuff
    var matchingItems:[MKMapItem] = []
    var searchMapView: MKMapView? = nil
    var tappedSearchTable:Bool = false

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
    @IBOutlet weak var requestNavBarView: UIView!
    @IBOutlet weak var requestNavBarLabel: UILabel!
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
    // Overall Search
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewMainSearchTF: UITextField!
    @IBOutlet weak var searchViewLocationSearchTF: UITextField!
    @IBOutlet weak var searchViewOriginY: NSLayoutConstraint!
    @IBOutlet weak var searchTable: UITableView!
    // Starting search/navigation bar
    @IBOutlet weak var HYVELabel: THLabel!
    @IBOutlet weak var HYVEView: UIView!
    @IBOutlet weak var HYVESearchTF: UITextField!
    
    
    /*
     * Action functions
     */
    @IBAction func postJobDidTouch(sender: AnyObject) {
        self.requestNavBarView.hidden = false
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
    
    @IBAction func returnFromSearchDidTouch(sender: AnyObject) {
        self.searchViewOriginY.constant -= 154
        self.searchTable.hidden = true
        self.HYVEView.hidden = false
        //self.navigationController!.navigationBar.hidden = false
    }
    
    @IBAction func searchButtonDidTouch(sender: AnyObject) {
    }
    
    @IBAction func returnFromRequestViewsDidTouch(sender: AnyObject) {
        self.requestNavBarView.hidden = true
        self.requestView.hidden = true
        self.jobMenuView.hidden = true
    }
    

    /*
     * Custom functions
     */
    // Name: colorWithHexString
    // Inputs: String
    // Outputs: UIColor
    // Function: Converts a hexString to a UIColor
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
            self.searchViewLocationSearchTF.text = address
        })
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
        if(!self.didStartPanMap) {
            self.postJobButton.hidden = true
            self.mapMarkerImageView.center.y -= 10
            self.didStartPanMap = true
        }
        if gestureRecognizer.state == .Ended {
            self.postJobButton.hidden = false
            self.mapMarkerImageView.center.y += 10
            self.didStartPanMap = false
            print("panning ended")
        }
    }
    
    // Name: tableView -- numberOfRowsInSection
    // Inputs: ...
    // Outputs: ...
    // Function: Sets the number of rows in each section of the tableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == searchTable) {
            return self.matchingItems.count
        }
        
        return self.jobMenuArray.count
    }
    
    // Name: tableView -- cellForRowAtIndexPath
    // Inputs: ...
    // Outputs: ...
    // Function: Sets up each cell of the tableView
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // If tableView == searchTable -> setup searchTable with locations
        if(tableView == searchTable) {
            let cell = tableView.dequeueReusableCellWithIdentifier("locationCell")!
            let selectedItem = matchingItems[indexPath.row].placemark
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.text = parseAddress(selectedItem)
            return cell
        }
        
        // Else setup selection for job request categories
        let menuCell = self.jobMenuTableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! jobMenuCell
        menuCell.menuTitle.text = self.jobMenuArray[indexPath.row].menuTitle
        menuCell.menuImage.image = self.jobMenuArray[indexPath.row].menuImage
        
        // Set cell selection color
        var bgColorView: UIView = UIView()
        bgColorView.backgroundColor = colorWithHexString("E5B924")
        menuCell.selectedBackgroundView = bgColorView
        
        return menuCell
    }
    
    // Name: tableView -- didSelectRowAtIndexPath
    // Inputs: ...
    // Outputs: ...
    // Function: Sets up what happens when a cell is selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // If tableView == searchTable -> setup selection for map
        if(tableView == searchTable) {
            let selectedItem = matchingItems[indexPath.row].placemark
            self.newLocationZoomIn(selectedItem)
            self.searchTable.hidden = true
        // Else setup selection for job request categories
        } else {
            print("selected")
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            self.requestView.hidden = false
            
            // Set and show navigation bar title
            self.requestNavBarLabel.text = "Request a Job"
            self.requestNavBarView.hidden = false
            
            // Hide jobMenuView
            self.jobMenuView.hidden = true
            
            // Set jobMenuView defaults
            self.categoryTF.text = self.jobMenuArray[indexPath.row].menuTitle
            self.offerTF.text = "$0.00"
            self.lifetimeTF.text = "0 Days, 0 Hours, 0 Minutes"
            self.addressTV.text = self.searchViewLocationSearchTF.text
        }
    }
    
    // Name: dismissKeyboard
    // Inputs: None
    // Outputs: None
    // Function: Custom function to end text editing for views by dismissing keyboard
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    // Name: animateTextField
    // Inputs: ...
    // Outputs: ...
    // Function: Custom function for pushing textFields up when editting
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
    
    // Name: textFieldDidBeginEditing
    // Inputs: ...
    // Outputs: ...
    // Function: Push view up if textField == offerTF || keyTF is edited
    func textFieldDidBeginEditing(textField: UITextField) {
        if(textField == offerTF || textField == keyTF) {
            self.animateTextField(textField, up:true)
        }
    }
    
    // Name: textFieldDidEndEditing
    // Inputs: ...
    // Outputs: ...
    // Function: Push view down if textfield == offerTF || keyTF is finished editing
    func textFieldDidEndEditing(textField: UITextField) {
        if(textField == offerTF || textField == keyTF) {
            self.animateTextField(textField, up:false)
        }
    }
    
    // Name: numberOfComponentsInPickerView
    // Inputs: ...
    // Outputs: ...
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
    
    // Name: pickerView -- numberOfRowsInComponent
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
    
    // Name: pickerView -- titleForRow
    // Inputs: ...
    // Outputs: ...
    // Function: Sets the title of rows in pickerViews
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title: String? = nil
        if(pickerView == self.categoryPicker) {
            return jobMenuArray[row].menuTitle
        } else {
            return "\(row)"
        }
    }
    
    // Name: pickerView -- viewForRow
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
        if(textField == self.offerTF) {
            if !(self.offerTF.text!.hasPrefix("$")) {
                self.offerTF.text = "$\(self.offerTF.text!)"
            } else {
                if (self.offerTF.text!.hasSuffix("$")) {
                    self.offerTF.text = ""
                }
            }
        }
    }
    
    // Name: searchTextFieldDidChange
    // Inputs: ...
    // Outputs: ...
    // Function: Function to search map for when searchViewLocationSearchTF is edited
    func searchTextFieldDidChange(textField: searchTextField) {
        if(textField == searchViewMainSearchTF) {
            // Do search for searchViewMainSearchTF
        } else {
            self.searchTable.hidden = false
            guard let mapView = self.mapView,
                let searchBarText = textField.text else { return }
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = searchBarText
            request.region = mapView.region
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler { response, _ in
                guard let response = response else {
                    return
                }
                self.matchingItems = response.mapItems
                print("item = \(self.matchingItems)")
                self.searchTable.reloadData()
            }
        }
    }
    
    // Name: searchTextFieldDidBeginEditing
    // Inputs: ...
    // Outputs: ...
    // Function: Function to search map for when searchViewLocationSearchTF starts being edited
    func searchTextFieldDidBeginEditing(textField: searchTextField) {
        if(textField == searchViewMainSearchTF) {
            self.searchTable.hidden = true
        } else if (textField == searchViewLocationSearchTF) {
            textField.text = ""
            self.searchTable.hidden = false
            guard let mapView = self.mapView,
                let searchBarText = textField.text else { return }
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = searchBarText
            request.region = mapView.region
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler { response, _ in
                guard let response = response else {
                    return
                }
                self.matchingItems = response.mapItems
                print("item = \(self.matchingItems)")
                self.searchTable.reloadData()
            }
        }
    }
    
    // Name: searchTextFieldDidEndEditing
    // Inputs: ...
    // Outputs: ...
    // Function: Function to reset searchViewLocationSearchTF text if user is finished editing
    func searchTextFieldDidEndEditing(textField: searchTextField) {
        if(textField == searchViewMainSearchTF) {
            
        } else if (textField == searchViewLocationSearchTF) {
            if(textField.text == "") {
                print("ended")
                textField.text = self.previousAddress!
            }
        }
    }
    
    // Name: textField -- shouldChangeCharactersInRange
    // Inputs: ...
    // Outputs: ...
    // Function: Stops accepting user input for textField under circumstances
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
    
    // Name: textViewDidBeginEditing
    // Inputs: ...
    // Outputs: ...
    // Function: If user edits textview, check textColor to make sure the color is returned to black
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    // Name: textViewDidChange
    // Inputs: ...
    // Outputs: ...
    // Function: If textView is changed and cleared, update it with placeholder text
    func textViewDidChange(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = PLACEHOLDER_TEXT
        }
    }
    
    // Name: textViewDidEndEditing
    // Inputs: ...
    // Outputs: ...
    // Function: If user finished editing the textView, check if empty. If yes, update it with placeholder text.
    func textViewDidEndEditing(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = PLACEHOLDER_TEXT
        }
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if(textField == HYVESearchTF) {
            self.HYVEView.hidden = true
            self.searchViewOriginY.constant += 154
            //self.searchTable.hidden = false
            self.searchViewMainSearchTF.becomeFirstResponder()
            return false
        } else if (textField == searchViewLocationSearchTF) {
            print("TOUCH ME")
            self.searchTable.hidden = false
        }
        return true
    }
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }

    func newLocationZoomIn(placemark:MKPlacemark){
        selectedPin = placemark
        self.mapView!.centerCoordinate = placemark.coordinate
        let reg = MKCoordinateRegionMakeWithDistance(placemark.coordinate, 1500, 1500)
        self.mapView!.setRegion(reg, animated: true)
    }
    
    //
    // Name: textChangeNotification
    // Inputs: ...
    // Outputs: ...
    // Function: If textField is
//    func textChangeNotification(notification: NSNotification) {
//        self.searchRecordsAsPerText(searchTextField.text!)
//    }
//    
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
//    
//    func searchRecordsAsPerText(string: String) {
//        searchArray.removeAllObjects()
//        for obj: [NSObject : AnyObject] in recordsArray {
//            var sTemp: String = obj["TEXT"]
//            var titleResultsRange: NSRange = sTemp.rangeOfString(string, options: NSCaseInsensitiveSearch)
//            if titleResultsRange.length > 0 {
//                searchArray.append(obj)
//            }
//        }
//        searchTable.reloadData()
//    }
    
    
    
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
        
        // UITextField as SearchBar
        self.searchViewOriginY.constant -= 154
        self.searchTable.hidden = true
        self.HYVESearchTF.delegate = self
        self.searchTable.delegate = self
        self.searchTable.dataSource = self
        self.searchViewLocationSearchTF.addTarget(self, action: #selector(homeVC.searchTextFieldDidChange(_:)), forControlEvents: .EditingChanged)
        self.searchViewLocationSearchTF.addTarget(self, action: #selector(homeVC.searchTextFieldDidBeginEditing(_:)), forControlEvents: .EditingDidBegin)
        self.searchViewLocationSearchTF.addTarget(self, action: #selector(homeVC.searchTextFieldDidEndEditing(_:)), forControlEvents: .EditingDidEnd)
        self.searchViewMainSearchTF.addTarget(self, action: #selector(homeVC.searchTextFieldDidBeginEditing(_:)), forControlEvents: .EditingDidBegin)
        // Customize THLabels (HYVELabel)
        self.HYVELabel.shadowColor = kShadowColor2
        self.HYVELabel.shadowOffset = kShadowOffset
        self.HYVELabel.shadowBlur = kShadowBlur
        self.HYVELabel.innerShadowColor = kShadowColor2
        self.HYVELabel.innerShadowOffset = kInnerShadowOffset
        self.HYVELabel.innerShadowBlur = kInnerShadowBlur
        self.HYVELabel.strokeColor = kStrokeColor
        self.HYVELabel.strokeSize = kStrokeSize
        self.HYVELabel.gradientStartColor = kGradientStartColor
        self.HYVELabel.gradientEndColor = kGradientEndColor
        
        // RequestView Navigation bar
        // Hide requestNavBarView to start
        self.requestNavBarView.hidden = true

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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



