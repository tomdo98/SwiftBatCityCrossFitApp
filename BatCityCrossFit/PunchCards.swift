//
//  PunchCards.swift
//  BatCityCrossFit
//
//  Created by Tommy Do on 9/17/17.
//  Copyright © 2017 Tommy Do. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import AudioToolbox

class PunchCards: UIViewController {
    
    @IBOutlet weak var PunchButton: UIButton!

    @IBOutlet weak var PunchRing: UIImageView!
    
    @IBOutlet weak var reloadbutton: UIButton!

var ref: DatabaseReference!

var messages: [DataSnapshot]! = []
var msglength: NSNumber = 1000
var storageRef: StorageReference!
var remoteConfig: RemoteConfig!
let imageCache = NSCache<NSString, UIImage>()
var keyboardOnScreen = false
var placeholderImage = UIImage(named: "ic_account_circle")
fileprivate var _refHandle: DatabaseHandle!
fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
var user: User?
var displayName = "Anonymous"
var mUserLoggedIn: String = ""
 
    @IBAction func RechargeButton(_ sender: Any) {
        let refreshAlert = UIAlertController(title: "Recharge", message: "Are you sure you want to recharge your card with 9 punches?", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            let date : Date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmm"
            let todaysDate = dateFormatter.string(from: date)
            
            self.ref.child("punch_cards").queryOrdered(byChild: "username").queryEqual(toValue: self.mUserLoggedIn).observeSingleEvent(of: .value, with: {(Snap) in
                if let snapDict = Snap.value as? [String:AnyObject]{
                    for each in snapDict{
                        print(snapDict.keys)
                        print(each.0)
                        let key1 = (each.0)
                        print(key1)
                        let userRef = self.ref.child("punch_cards").child(key1)
                        userRef.updateChildValues(["punchesleft": "9"])
                        self.MarkUsed(Punches: "9")
                        //self.PunchButton.isEnabled = true
                        self.card_stat(data: [Constants.card_stat.stat_type: "recharge_card"], lastupdated: todaysDate)
                    }
                    
                }
                else
                {
                    self.punch_cards(data: [Constants.punch_cards.username : self.mUserLoggedIn], user: self.mUserLoggedIn, punchesleft: "9", last_updated: todaysDate)
                    self.MarkUsed(Punches: "9")
                }
            })
            
            
            
            
            let alert = UIAlertController(title: "Recharged", message: "Thank you for recharging your card.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            let alert = UIAlertController(title: "Recharge cancelled", message: "Recharge cancelled.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        present(refreshAlert, animated: true, completion: nil)
        
        

    }


@IBAction func PunchButtonAction(_ sender: Any) {
    
    let date : Date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmm"
    let todaysDate = dateFormatter.string(from: date)
   print(todaysDate)
    var pleft:String!
  
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    print(mUserLoggedIn)
    ref.child("punch_cards")
        .queryOrdered(byChild: "username")
        .queryEqual(toValue: mUserLoggedIn)
        .observeSingleEvent(of: .value, with: {(Snap) in
        if !Snap.exists() {
            return
        }

        for rest in Snap.children.allObjects as! [DataSnapshot] {
            
            guard let restDict = rest.value as? [String: Any] else { continue }
            pleft = restDict["punchesleft"] as! String
            var reduce_count = Int(pleft)
            reduce_count = reduce_count! - 1
            pleft = String(describing: reduce_count ?? 0)
            self.MarkUsed(Punches: pleft!)
            if (reduce_count == 0)
            {
                self.PunchButton.isEnabled = false
            }
        }

        if let snapDict = Snap.value as? [String:AnyObject]{
            self.card_stat(data: [Constants.card_stat.stat_type: "use_punch_cf"], lastupdated: todaysDate)
            for each in snapDict{
                let key1 = (each.0)
               let userRef = self.ref.child("punch_cards").child(key1)
                    userRef.updateChildValues(["punchesleft": pleft])
                
            }

        }
        
    })
    }
override func viewDidLoad() {
    super.viewDidLoad()
    
    configureAuth()
    // Do any additional setup after loading the view, typically from a nib.
}

@IBAction func SignOutButton(_ sender: Any) {
    do {
        try Auth.auth().signOut()
    } catch {
        print("unable to sign out: \(error)")
    }
}
    

    
    func card_stat(data: [String:String],lastupdated: String) {
        var mdata = data
        // add name to message and then data to firebase database
        mdata[Constants.card_stat.last_updated] = lastupdated
       // mdata[Constants.card_stat.stat_type] = stat_type
        mdata[Constants.card_stat.username] = mUserLoggedIn
        ref.child("card_stat").childByAutoId().setValue(mdata)
    }
    
    func sendMessage(data: [String:String]) {
        var mdata = data
        // add name to message and then data to firebase database
        mdata[Constants.MessageFields.name] = displayName
        ref.child("messages").childByAutoId().setValue(mdata)
    }
    
func configureAuth() {
    //  let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
    // FUIAuth.defaultAuthUI()?.providers = provider
    
    // listen for changes in the authorization state
    _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
        // refresh table data
        // self.messages.removeAll(keepingCapacity: false)
        //  self.messagesTable.reloadData()
        
        // check if there is a current user
        if let activeUser = user {
            // check if the current app user is the current FIRUser
            if self.user != activeUser {
                self.user = activeUser
                self.signedInStatus(isSignedIn: true)
                let name = user!.email!.components(separatedBy: "@")[0]
                self.displayName = name
                self.mUserLoggedIn = (user?.email)!
                self.getcurrentpunches()
            }
        } else {
            // user must sign in
            self.signedInStatus(isSignedIn: false)
            self.loginSession()
        }
    }
}
    
    func getcurrentpunches()
    {
        
        var pleft:String!
        ref.child("punch_cards").queryOrdered(byChild: "username").queryEqual(toValue: mUserLoggedIn).observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
                self.PunchButton.isEnabled = false
                return
            }
            
            for rest in Snap.children.allObjects as! [DataSnapshot] {
                
                guard let restDict = rest.value as? [String: Any] else { continue }
                pleft = restDict["punchesleft"] as! String
                self.MarkUsed(Punches: pleft!)
                if (pleft == "0")
                {
                    self.PunchButton.isEnabled = false
                }
            }
        })
    }
    

func configureDatabase() {
    ref = Database.database().reference()
    // listen for new messages in the firebase database
    _refHandle = ref.child("messages").observe(.childAdded) { (snapshot: DataSnapshot)in
        self.messages.append(snapshot)
        //   self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
        //  self.scrollToBottomMessage()
    }
}

func configureStorage() {
    storageRef = Storage.storage().reference()
}

//deinit {
//    ref.child("messages").removeObserver(withHandle: _refHandle)
//    Auth.auth().removeStateDidChangeListener(_authHandle)/
//}

// MARK: Remote Config

func configureRemoteConfig() {
    // create remote config setting to enable developer mode
    let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
    remoteConfig = RemoteConfig.remoteConfig()
    remoteConfig.configSettings = remoteConfigSettings!
}

func fetchConfig() {
    var expirationDuration: Double = 3600
    // if in developer mode, set cacheExpiration 0 so each fetch will retrieve values from the server
    if remoteConfig.configSettings.isDeveloperModeEnabled {
        expirationDuration = 0
    }
    
    // cacheExpirationSeconds is set to cacheExpiration to make fetching faser in developer mode
    remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
        if status == .success {
            print("Config fetched!")
            self.remoteConfig.activateFetched()
            let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
            if friendlyMsgLength.source != .static {
                self.msglength = friendlyMsgLength.numberValue!
                print("Friendly msg length config: \(self.msglength)")
            }
        } else {
            print("Config not fetched")
            print("Error \(String(describing: error))")
        }
    }
}

    func MarkUsed(Punches: String)
        
    {
        if (Punches == "0")
        {
            self.PunchRing.image = #imageLiteral(resourceName: "ring9")
            self.PunchButton.isEnabled = false
            self.reloadbutton.isEnabled = true
        }
        if (Punches == "1")
        {
            self.PunchButton.isEnabled = true
            self.PunchRing.image = #imageLiteral(resourceName: "ring8")
            self.reloadbutton.isEnabled = false
            
        }
        if (Punches == "2")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring7")
            
        }
        if (Punches == "3")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring6")
            
        }
        if (Punches == "4")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring5")
            
        }
        if (Punches == "5")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring4")
            
        }
        if (Punches == "6")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring3")
            
        }
        if (Punches == "7")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring2")
            
        }
        if (Punches == "8")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring1")
            
        }
        if (Punches == "9")
        {
            self.PunchButton.isEnabled = true
            self.reloadbutton.isEnabled = false
            self.PunchRing.image = #imageLiteral(resourceName: "ring0")
        }
    }

// MARK: Sign In and Out

func signedInStatus(isSignedIn: Bool) {
    //   signInButton.isHidden = isSignedIn
    //   signOutButton.isHidden = !isSignedIn
    //   messagesTable.isHidden = !isSignedIn
    //   messageTextField.isHidden = !isSignedIn
    //   sendButton.isHidden = !isSignedIn
    //   imageMessage.isHidden = !isSignedIn
    //   backgroundBlur.effect = UIBlurEffect(style: .light)
    
    if isSignedIn {
        // remove background blur (will use when showing image messages)
        //     messagesTable.rowHeight = UITableViewAutomaticDimension
        //     messagesTable.estimatedRowHeight = 122.0
        //     backgroundBlur.effect = nil
        //     messageTextField.delegate = self
        //     subscribeToKeyboardNotifications()
        configureDatabase()
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
    }
}

func loginSession() {
    let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
    present(authViewController, animated: true, completion: nil)
}
    func punch_cards(data: [String:String],user: String, punchesleft: String, last_updated: String  )
    {
        var mdata = data
        mdata[Constants.punch_cards.punchesleft] = punchesleft
        mdata[Constants.punch_cards.last_updated] = last_updated
        mdata[Constants.punch_cards.username] = mUserLoggedIn
        
        ref.child("punch_cards").childByAutoId().setValue(mdata)
    }
}
