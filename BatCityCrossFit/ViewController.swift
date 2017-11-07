//
//  ViewController.swift
//  BatCityCrossFit
//
//  Created by Tommy Do on 9/16/17.
//  Copyright © 2017 Tommy Do. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class ViewController: UIViewController {
    
    
    @IBOutlet weak var rewardtext: UILabel!
    @IBOutlet weak var rewardimage: UIImageView!
    
    @IBOutlet weak var CheckInStatus: UILabel!
    var lastupdated:String = ""
    var xaweek:String = ""
    var weekfound:String = ""
    var gonethisweek:String = ""
    
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
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        configureAuth()
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func SignOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {
            print("unable to sign out: \(error)")
        }
    }
    
//    @IBAction func SignOutButton(_ sender: Any) {
//        do {
//            try Auth.auth().signOut()
//        } catch {
//            print("unable to sign out: \(error)")
//        }
//    }
    

    
    func configureAuth() {

        _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
            if let activeUser = user {
                if self.user != activeUser {
                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                    self.mUserLoggedIn = (user?.email)!
                    self.getBalance()
                }
            } else {
                self.signedInStatus(isSignedIn: false)
                self.loginSession()
            }
        }
    }
    
    func configureDatabase() {
        ref = Database.database().reference()
        _refHandle = ref.child("messages").observe(.childAdded) { (snapshot: DataSnapshot)in
            self.messages.append(snapshot)
        }
    }
    
  //  func configureStorage() {
  //      storageRef = Storage.storage().reference()
  //  }
    
    deinit {
        ref.child("messages").removeObserver(withHandle: _refHandle)
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    // MARK: Remote Config
    
//    func configureRemoteConfig() {
//        // create remote config setting to enable developer mode
//        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
//        remoteConfig = RemoteConfig.remoteConfig()
//        remoteConfig.configSettings = remoteConfigSettings!
//    }
//    
//    func fetchConfig() {
//        var expirationDuration: Double = 3600
//        // if in developer mode, set cacheExpiration 0 so each fetch will retrieve values from the server
//        if remoteConfig.configSettings.isDeveloperModeEnabled {
//            expirationDuration = 0
//        }
//        
//        // cacheExpirationSeconds is set to cacheExpiration to make fetching faser in developer mode
//        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
//            if status == .success {
//                print("Config fetched!")
//                self.remoteConfig.activateFetched()
//                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
//                if friendlyMsgLength.source != .static {
//                    self.msglength = friendlyMsgLength.numberValue!
//                    print("Friendly msg length config: \(self.msglength)")
//                }
//            } else {
//                print("Config not fetched")
//                print("Error \(String(describing: error))")
//            }
//        }
//    }
    func getBalance()
    {
        print("get balance")
        
        var balance:String!
        var datex:String!
        var weekchecked:String!
        var stringweek:String!
        var messges:String!
     //   let date : Date = Date()
        let dateFormatter = DateFormatter()
        let dateFormatter2 = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter2.dateFormat = "yyyyMMdd"
        let calendar = Calendar.current
        let thisweek = calendar.component(.weekOfYear, from: Date.init(timeIntervalSinceNow: 0))
        stringweek = String(describing: thisweek )
        //  let todaysDate = dateFormatter.string(from: date)
     //   let todaysDate2 = dateFormatter2.string(from: date)
        
        ref.child("SignInRunningBalance").queryOrdered(byChild: "username").queryEqual(toValue: mUserLoggedIn).observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
              //  self.SignInRunningBalance(data: [Constants.SignInRunningBalance.username: self.mUserLoggedIn], lastupdated: todaysDate2, balance: "0")
                return
            }
            else
            {
                for rest in Snap.children.allObjects as! [DataSnapshot] {
                    
                    guard let restDict = rest.value as? [String: Any] else { continue }
                    balance = restDict["balance"] as! String
                    datex = restDict["last_updated"] as! String
                    messges = restDict["messagetoclient"] as! String
                    self.xaweek = restDict["xaweek"] as! String
                    self.weekfound = restDict["weekofyear"] as! String
                    if (self.weekfound != stringweek)
                    {
                        weekchecked = "0"
                    }
                    else
                    {
                        weekchecked = self.gonethisweek
                    }
                    self.gonethisweek =  restDict["timesthisweek"] as! String
                    self.lastupdated = datex
                   // self.CheckInStatus.text = " Your check in balance is: " + balance + ".\n You last checked in on " + datex + ".\n You have checked in " + self.gonethisweek + " times this week.\n You are on the " + self.xaweek + " plan."
                    self.CheckInStatus.text = " Your check in balance is: " + balance + ".\n You last checked in on " + datex + ".\n You have checked in " + weekchecked + " times this week.\n You are on the " + self.xaweek + " plan. \n Messages: " + messges
                    self.setprizes(prize: Int(balance)!)
                }
            }
        })
    }
    
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {

        
        if isSignedIn {

            configureDatabase()
         //   configureStorage()
         //   configureRemoteConfig()
          //  fetchConfig()
        }
    }
    
    func loginSession() {
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func setprizes (prize: Int)
    {
        var amtleft: Int = 0
        
        if (prize >= 0 && prize <= 5)
        {
            amtleft = 6 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a Koozie!"
            rewardimage.image = #imageLiteral(resourceName: "koozie")
        }
        if (prize == 6)
        {
            rewardtext.text = "You just earned a Koozie! Go get it!"
            rewardimage.image = #imageLiteral(resourceName: "koozie")
        }
        if (prize >= 7 && prize <= 14)
        {
            amtleft = 15 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a water bottle!"
            self.rewardimage.image = #imageLiteral(resourceName: "waterbottle")
        }
        if (prize == 15)
        {
            rewardtext.text = "You just earned a water bottle! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "waterbottle")
        }
        if (prize >= 16 && prize <= 20)
        {
            amtleft = 21 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a T-shirt!"
            self.rewardimage.image = #imageLiteral(resourceName: "tshirt")
        }
        if (prize == 21)
        {
            rewardtext.text = "You just earned a t-shirt! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "tshirt")
        }
        if (prize >= 22 && prize <= 39)
        {
            amtleft = 40 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a sunglasses!"
            self.rewardimage.image = #imageLiteral(resourceName: "sunglasses")
        }
        if (prize == 40)
        {
            rewardtext.text = "You just earned a pair of sunglasses! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "sunglasses")
        }
        if (prize >= 41 && prize <= 59)
        {
            amtleft = 60 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a ball cap!"
            self.rewardimage.image = #imageLiteral(resourceName: "baseballcap")
        }
        if (prize == 60)
        {
            rewardtext.text = "You just earned a ball cap! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "baseballcap")
        }
        if (prize >= 61 && prize <= 79)
        {
            amtleft = 80 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a tote bag!"
            self.rewardimage.image = #imageLiteral(resourceName: "bag")
        }
        if (prize == 80)
        {
            rewardtext.text = "You just earned a tote bag! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "bag")
        }
        if (prize >= 81 && prize <= 99)
        {
            amtleft = 100 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 100)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 101 && prize <= 199)
        {
            amtleft = 200 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 200)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 201 && prize <= 299)
        {
            amtleft = 300 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 300)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 301 && prize <= 399)
        {
            amtleft = 400 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 400)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 401 && prize <= 499)
        {
            amtleft = 500 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 500)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 501 && prize <= 599)
        {
            amtleft = 600 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 600)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 601 && prize <= 699)
        {
            amtleft = 700 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 700)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 701 && prize <= 799)
        {
            amtleft = 800 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 800)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 801 && prize <= 899)
        {
            amtleft = 900 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 900)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 901 && prize <= 999)
        {
            amtleft = 1000 - prize
            rewardtext.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 1000)
        {
            rewardtext.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
    }

}


