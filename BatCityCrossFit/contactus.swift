//
//  contact us
//  BatCityCrossFit
//
//  Created by Tommy Do on 9/25/17.
//  Copyright © 2017 Tommy Do. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class contactus: UIViewController, UINavigationControllerDelegate {
    var ref: DatabaseReference!
    var messages: [DataSnapshot]! = []
    fileprivate var _refHandle: DatabaseHandle!
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    var user: User?
    var displayName = "Anonymous"
    var mUserLoggedIn: String = ""
    


    @IBOutlet weak var textfield: UITextField!
    
    @IBOutlet weak var sendbutton: UIButton!
    
    
    override func viewDidLoad() {
        configureAuth()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //   unsubscribeFromAllNotifications()
    }
    
    @IBAction func sendcommentbutton(_ sender: Any) {
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let todaysDate = dateFormatter.string(from: date)
        print(todaysDate)
    sendcomments(data: [Constants.batcitycomments.username: self.mUserLoggedIn], comment: self.textfield.text!, datecomment: todaysDate)
        self.textfield.text = ""
        let alert = UIAlertController(title: "Message Sent", message: "Thank you for your message.", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func configureAuth() {
        let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        // listen for changes in the authorization state
        _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in

            
            // check if there is a current user
            if let activeUser = user {
                // check if the current app user is the current FIRUser
                if self.user != activeUser {
                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                    self.mUserLoggedIn = (user?.email)!
                }
            } else {
                // user must sign in
                self.signedInStatus(isSignedIn: false)
                self.loginSession()
            }
        }
    }
    
    func configureDatabase() {
        ref = Database.database().reference()
        // listen for new messages in the firebase database
        _refHandle = ref.child("batcitycomments").observe(.childAdded) { (snapshot: DataSnapshot)in
       //     self.messages.append(snapshot)
         //   print(self.messages)

        }
    }
    
    deinit {
        ref.child("batcitycomments").removeObserver(withHandle: _refHandle)
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    func signedInStatus(isSignedIn: Bool) {
        
        if isSignedIn {
            configureDatabase()
        }
    }
    
    func loginSession() {
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    


    func sendcomments(data: [String:String],comment: String, datecomment: String) {
        var mdata = data
        // add name to message and then data to firebase database
        mdata[Constants.batcitycomments.comment] = comment
        mdata[Constants.batcitycomments.datecomment] = datecomment
        mdata[Constants.batcitycomments.username] = self.mUserLoggedIn
        ref.child("batcitycomments").childByAutoId().setValue(mdata)
    }
}

