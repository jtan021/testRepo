//
//  loginRegisterVC.swift
//  Hyve V0.06
//
//  Created by Jonathan Tan on 6/11/16.
//  Copyright © 2016 Jonathan Tan. All rights reserved.
//

import UIKit
import Parse

class loginRegisterVC: UIViewController, UITextFieldDelegate {
    /*
     * Constants
     */
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
    
    // Text checking character set
    let characterSet:NSCharacterSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
    
    /*
     * Outlets
     */
    // LoginView
    @IBOutlet weak var HYVELabel: THLabel!
    @IBOutlet weak var loginUsernameTF: UITextField!
    @IBOutlet weak var loginPasswordTF: UITextField!
    
    // RegistrationView
    @IBOutlet weak var viewToDim: UIView!
    @IBOutlet weak var HYVERegistrationLabel: THLabel!
    @IBOutlet weak var registrationView: UIView!
    @IBOutlet weak var registrationFirstNameTF: UITextField!
    @IBOutlet weak var registrationLastNameTF: UITextField!
    @IBOutlet weak var registrationEmailTF: UITextField!
    @IBOutlet weak var registrationConfirmPWTF: UITextField!
    
    /*
     * Action functions
     */
    @IBAction func loginDidTouch(sender: AnyObject) {
        // First check that all fields are filled out.
        if (loginUsernameTF.text == "" || loginPasswordTF.text == "") {
            self.displayAlert("Missing field(s)", message: "All fields must be filled out.")
        } else {
            // If fields are all filled out, attempt to log user in
            PFUser.logInWithUsernameInBackground(loginUsernameTF.text!, password:loginPasswordTF.text!) {
                (user: PFUser?, error: NSError?) -> Void in
                if user != nil {
                    self.performSegueWithIdentifier("successfulLoginSegue", sender: self)
                    print("Login Successful")
                } else {
                    if let errorString = error?.userInfo["error"] as? NSString {
                        self.displayAlert("Login failed", message: errorString as String)
                    }
                }
            }
        }
    }
    
    @IBAction func openRegistrationDidTouch(sender: AnyObject) {
        // First check that all fields are filled out.
        if (loginUsernameTF.text == "" || loginPasswordTF.text == "") {
            self.displayAlert("Missing field(s)", message: "Please enter your desired username & password to continue.")
        } else if (loginUsernameTF.text!.rangeOfCharacterFromSet(characterSet.invertedSet) != nil) {
            self.displayAlert("Invalid username", message: "Acceptable characters for a Hyve account username include letters a-z, A-Z, and numbers 0-9")
        } else {
            // Second check that the entered username is not taken
            let query = PFQuery(className: "_User")
            query.whereKey("username", equalTo: loginUsernameTF.text!)
            query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
                if error == nil {
                    if (objects!.count > 0) {
                        print("username is taken")
                        self.displayAlert("Account unavailable", message: "Username is already in use.")
                    } else {
                        print("username is available")
                        
                        // Since fields are not nil and username is available, show the registrationView
                        self.viewToDim.hidden = false
                        self.registrationView.hidden = false
                    }
                } else {
                    print(error)
                }
            }
        }
    }
    
    @IBAction func createAccountDidTouch(sender: AnyObject) {
        // First check that all fields are filled out.
        if (registrationFirstNameTF.text == "" || registrationLastNameTF.text == "" || registrationConfirmPWTF.text == "" || registrationEmailTF.text == "") {
            self.displayAlert("Missing field(s)", message: "All fields must be filled out.")
            return
        } else {
            // Second check that the two passwords entered match
            if (loginPasswordTF.text != registrationConfirmPWTF.text) {
                self.displayAlert("Invalid password", message: "The confirmed password must be identical to the previously entered password.")
                return
            } else {
                // Since fields are not nil and the passwords match, attempt to create the account
                let user = PFUser()
                user.username = loginUsernameTF.text
                user.password = registrationConfirmPWTF.text
                user.email = registrationEmailTF.text
                user["firstName"] = registrationFirstNameTF.text
                user["lastName"] = registrationLastNameTF.text
                user["currentLAT"] = 0
                user["currentLONG"] = 0
                let image = UIImagePNGRepresentation(UIImage(named: "gender_neutral_user")!)
                let profilePic = PFFile(name: "profile.png", data: image!)
                user["profilePic"] = profilePic
                user.signUpInBackgroundWithBlock {
                    (succeeded, error) -> Void in
                    // If account creation failed, display error
                    if let error = error {
                        if let errorString = error.userInfo["error"] as? NSString {
                            self.displayAlert("Registration failed", message: errorString as String)
                        }
                    } else {
                        // Else account has been successfully registered, hide registrationView
                        let newFriendObject = PFObject(className: "friends")
                        newFriendObject["username"] = self.loginUsernameTF.text
                        newFriendObject["friendsList"] = ""
                        newFriendObject["pendingFrom"] = ""
                        newFriendObject["pendingTo"] = ""
                        let defaultACL = PFACL()
                        defaultACL.publicWriteAccess = true
                        defaultACL.publicReadAccess = true
                        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser:true)
                        newFriendObject.ACL = defaultACL
                        newFriendObject.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                print("Successful registration")
                                self.viewToDim.hidden = true
                                self.registrationView.hidden = true
                                self.displayAlert("\(self.loginUsernameTF.text!) successfully registered", message: "Welcome to Hyve.")
                                self.performSegueWithIdentifier("successfulLoginSegue", sender: self)
                            } else {
                                print("registerDidTouch(1): \(error!) \(error!.description)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func returnToLoginDidTouch(sender: AnyObject) {
        self.registrationView.hidden = true
        self.viewToDim.hidden = true
    }
    
    /*
     * Custom functions
     */
    
    // displayAlert
    // Inputs: title:String, message:String
    // Output: UIAlertAction
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:  UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // DismissKeyboard()
    // Dismisses the keyboard if areas outside of editable text are tapped
    func DismissKeyboard() {
        view.endEditing(true)
    }
    
    // textFieldShouldReturn()
    // Add's done button to textfield
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    /*
     * Overrided functions
     */
    override func viewDidLoad() {
        // Hide registrationView
        self.viewToDim.hidden = true
        self.registrationView.hidden = true
        
        // Customize THLabels (HYVELabel & HYVERegistrationLabel)
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
        
        self.HYVERegistrationLabel.shadowColor = kShadowColor2
        self.HYVERegistrationLabel.shadowOffset = kShadowOffset
        self.HYVERegistrationLabel.shadowBlur = kShadowBlur
        self.HYVERegistrationLabel.innerShadowColor = kShadowColor2
        self.HYVERegistrationLabel.innerShadowOffset = kInnerShadowOffset
        self.HYVERegistrationLabel.innerShadowBlur = kInnerShadowBlur
        self.HYVERegistrationLabel.strokeColor = kStrokeColor
        self.HYVERegistrationLabel.strokeSize = kStrokeSize
        self.HYVERegistrationLabel.gradientStartColor = kGradientStartColor
        self.HYVERegistrationLabel.gradientEndColor = kGradientEndColor
        
        // Adds gesture so keyboard is dismissed when areas outside of editable text are tapped
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loginRegisterVC.DismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Set textfield delegates
        self.loginUsernameTF.delegate = self
        self.loginPasswordTF.delegate = self
        self.registrationFirstNameTF.delegate = self
        self.registrationLastNameTF.delegate = self
        self.registrationEmailTF.delegate = self
        self.registrationConfirmPWTF.delegate = self
        
        // Add Done button to all textfield keyboards
        self.loginUsernameTF.returnKeyType = UIReturnKeyType.Done
        self.loginPasswordTF.returnKeyType = UIReturnKeyType.Done
        self.registrationFirstNameTF.returnKeyType = UIReturnKeyType.Done
        self.registrationLastNameTF.returnKeyType = UIReturnKeyType.Done
        self.registrationEmailTF.returnKeyType = UIReturnKeyType.Done
        self.registrationConfirmPWTF.returnKeyType = UIReturnKeyType.Done
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if user is already logged in
        let currentUser = PFUser.currentUser()
        if currentUser?.username != nil {
            // If yes, skip login page and go to main view
            performSegueWithIdentifier("successfulLoginSegue", sender: self)
        }
    }
}
