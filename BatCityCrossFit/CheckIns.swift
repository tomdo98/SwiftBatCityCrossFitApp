//
//  CheckIns.swift
//  BatCityCrossFit
//
//  Created by Tommy Do on 9/22/17.
//  Copyright © 2017 Tommy Do. All rights reserved.
//

import Foundation
import Foundation
import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import AudioToolbox
import MapKit
import CoreLocation
import AVFoundation

class CheckIns: UIViewController,CLLocationManagerDelegate, AVCaptureMetadataOutputObjectsDelegate  {
  var locationManager = CLLocationManager()
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var lastupdated:String = ""
    var xaweek:String = ""
    var weekfound:String = ""
    var gonethisweek:String = ""
    
    @IBOutlet weak var CheckInStatus: UILabel!
    @IBOutlet weak var rewardsstatus: UILabel!
    @IBOutlet weak var rewardimage: UIImageView!
    
    
    var balance: String = ""
    var passcode: String = ""
    
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
    var addressString : String = ""

    
    
    let regionRadius: CLLocationDistance = 50
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 1, regionRadius * 1)
        MapCheckIn.setRegion(coordinateRegion, animated: true)
    }
    
    @IBOutlet weak var MapCheckIn: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        



        
        configureAuth()
       // getBalance()
        //getAddress()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.distanceFilter = 100
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        }

            }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Found user's location: \(location)")
                    let latitude: Double = location.coordinate.latitude
                    let longitude: Double = location.coordinate.longitude
                    print(latitude)
                    print(longitude)
                    getAddressFromLatLon(pdblLatitude: location.coordinate.latitude, withLongitude: location.coordinate.longitude)
                    let initialLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    centerMapOnLocation(location: initialLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        var stringweek:String!
        let date : Date = Date()
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "MM/dd/yyyy"
        let todaysDate2 = dateFormatter2.string(from: date)
        let calendar = Calendar.current
        let thisweek = calendar.component(.weekOfYear, from: Date.init(timeIntervalSinceNow: 0))
        stringweek = String(describing: thisweek )

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
       //     messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
           
            if metadataObj.stringValue != nil {
                print(metadataObj.stringValue)
                
                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
                self.captureSession?.stopRunning()
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    self.qrCodeFrameView?.removeFromSuperview()
                    if (todaysDate2 == self.lastupdated)
                    {
                        self.videoPreviewLayer?.removeFromSuperlayer()
                        self.qrCodeFrameView?.removeFromSuperview()
                        let alert = UIAlertController(title: "Check In Failed", message: "You have already checked in today. You can only check in once a day", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else
                    {
                        //self.xaweek = restDict["xaweek"] as! String
                        //self.weekfound = restDict["weekofyear"] as! String
                        //self.gonethisweek =  restDict["timesthisweek"] as! String
                        // Your code with delay
                        if (self.xaweek == "3X" && self.weekfound == stringweek && self.gonethisweek >= "3" )
                        {
                            let alert = UIAlertController(title: "Check In Failed", message: "You are on a 3x a week program. You have already checked in 3 times this week.", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        else
                        {
                            
                            
                            if (metadataObj.stringValue == self.passcode)
                            {
                                print("found")
                                self.upBalance()
                                self.classruntotals()
                            }
                            else{
                                print("notfound")
                            }
                        }
                    }
                    
                    
                    
                    
                }
            }
            
        }
    }
    
    
    @IBAction func GetLoc(_ sender: Any) {
        getaccesscode()
        //upBalance()
        //   var locManager = CLLocationManager()
        launchqr()
    }
    
    func getAddressFromLatLon(pdblLatitude: Double, withLongitude pdblLongitude: Double) {
        print("get latlon")

        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let lat: Double = Double("\(pdblLatitude)")!
        //21.228124
        let lon: Double = Double("\(pdblLongitude)")!
        //72.833770
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = lat
        center.longitude = lon
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                else
                {
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                //    print(pm.country!)
                //    print(pm.locality!)
                //    print(pm.subLocality!)
                //    print(pm.thoroughfare!)
                //    print(pm.postalCode!)
                //    print(pm.subThoroughfare!)
                  //  var addressString : String = ""
                    if pm.subLocality != nil {
                        self.addressString = self.addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        self.addressString = self.addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        self.addressString = self.addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        self.addressString = self.addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        self.addressString = self.addressString + pm.postalCode! + " "
                    }
                    }
                    
                 //   print(self.addressString)
                }
        })
        print("end get latlon")
    }

    func launchqr()
    {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            // Move the message label and top bar to the front
            
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }

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
                    self.getBalance()
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
        _refHandle = ref.child("messages").observe(.childAdded) { (snapshot: DataSnapshot)in
            self.messages.append(snapshot)
            //   self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
            //  self.scrollToBottomMessage()
        }
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    deinit {
        ref.child("messages").removeObserver(withHandle: _refHandle)
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
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
    
    func getAddress()
    {


    }
    
    func getBalance()
    {
        print("get balance")

        var balance:String!
        var datex:String!
        var weekchecked:String!
        var stringweek:String!
        var yesterday:String!
     //   let date : Date = Date()
        let dateFormatter = DateFormatter()
        let dateFormatter2 = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter2.dateFormat = "yyyyMMdd"
        let calendar = Calendar.current
        let thisweek = calendar.component(.weekOfYear, from: Date.init(timeIntervalSinceNow: 0))
        stringweek = String(describing: thisweek )
        yesterday = String(describing: Date().yesterday)
      //  let todaysDate = dateFormatter.string(from: date)
      //  let todaysDate2 = dateFormatter2.string(from: date)
        
        ref.child("SignInRunningBalance").queryOrdered(byChild: "username").queryEqual(toValue: mUserLoggedIn).observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
               //  self.SignInRunningBalance(data: [Constants.SignInRunningBalance.username: self.mUserLoggedIn], lastupdated: yesterday, balance: "0", )
                self.SignInRunningBalance(data: [Constants.SignInRunningBalance.username: self.mUserLoggedIn], lastupdated: yesterday, balance: "0", active: "a", messagetoclient: "", timesthisweek: "0", weekofyear: "0", xaweek1: "Unlimited")
                return
            }
            else
            {
                for rest in Snap.children.allObjects as! [DataSnapshot] {
                    
                    guard let restDict = rest.value as? [String: Any] else { continue }
                    balance = restDict["balance"] as! String
                    datex = restDict["last_updated"] as! String
                    self.xaweek = restDict["xaweek"] as! String
                    self.weekfound = restDict["weekofyear"] as! String
                    self.gonethisweek =  restDict["timesthisweek"] as! String
                    self.lastupdated = datex
                    if (self.weekfound != stringweek)
                    {
                        weekchecked = "0"
                    }
                    else
                    {
                        weekchecked = self.gonethisweek
                    }
                  //  self.CheckInStatus.text = " Your check in balance is: " + balance + ".\n You last checked in on " + datex + ".\n You have checked in " + self.gonethisweek + " times this week.\n You are on the " + self.xaweek + " plan."
                    self.CheckInStatus.text = " Your check in balance is: " + balance + ".\n You last checked in on " + datex + ".\n You have checked in " + weekchecked + " times this week.\n You are on the " + self.xaweek + " plan."
                    self.setprizes(prize: Int(balance)!)
                }
            }
        })
    }
    
    func upBalance()
    {
        
        var balance:String!
        var weekofyear:String!
        var stringweek:String!
        var timesthisweek:String!
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let todaysDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "yyyyMMdd_HH"
        let hour = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let today1 = dateFormatter.string(from: date)
        
        let calendar = Calendar.current
        let thisweek = calendar.component(.weekOfYear, from: Date.init(timeIntervalSinceNow: 0))
        //print(thisweek)
        
        ref.child("SignInRunningBalance").queryOrdered(byChild: "username").queryEqual(toValue: mUserLoggedIn).observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
                return
            }
            else
            {
                for rest in Snap.children.allObjects as! [DataSnapshot] {
                    
                    guard let restDict = rest.value as? [String: Any] else { continue }
                    balance = restDict["balance"] as! String
                    weekofyear = restDict["weekofyear"] as! String
                    stringweek = String(describing: thisweek )
                    
                    timesthisweek = restDict["timesthisweek"] as! String
                    
                    
                    var increase_count = Int(balance)
                    var timesweek_int = Int(timesthisweek)
                    
                    if (weekofyear != stringweek)
                    {
                        timesweek_int = 1
                    }
                    else
                    {
                        timesweek_int = timesweek_int! + 1
                    }
                    increase_count = increase_count! + 1
                    
                    balance = String(describing: increase_count ?? 0)
                    timesthisweek = String(describing: timesweek_int ?? 0)
                    
                  //  self.CheckInStatus.text = "Your check in balance is: " + balance + ". Your last checked in on " + today1
                    self.getBalance()
                    self.setprizes(prize: Int(balance)!)
                }
            }
            
            if let snapDict = Snap.value as? [String:AnyObject]{
                for each in snapDict{
                    let key1 = (each.0)
                    let userRef = self.ref.child("SignInRunningBalance").child(key1)
                    userRef.updateChildValues(["balance": balance])
                    userRef.updateChildValues(["last_updated": today1])
                    userRef.updateChildValues(["timesthisweek": timesthisweek])
                    
                    
                    
                    userRef.updateChildValues(["weekofyear": stringweek])
                    self.lastupdated = today1
                    self.SignIn(data: [Constants.SignIn.username: self.mUserLoggedIn], balance_snap: balance, date_checkin: todaysDate, date_hour: hour, location: self.addressString, type: "check in")
                    let alert = UIAlertController(title: "Check In Succeeded", message: "You have successfully checked in today.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
            }
        })
    }
    
    func setprizes (prize: Int)
    {
        var amtleft: Int = 0
        
        if (prize >= 0 && prize <= 5)
        {
            amtleft = 6 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a Koozie!"
            rewardimage.image = #imageLiteral(resourceName: "koozie")
        }
        if (prize == 6)
        {
            rewardsstatus.text = "You just earned a Koozie! Go get it!"
            rewardimage.image = #imageLiteral(resourceName: "koozie")
        }
        if (prize >= 7 && prize <= 14)
        {
            amtleft = 15 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a water bottle!"
            self.rewardimage.image = #imageLiteral(resourceName: "waterbottle")
        }
        if (prize == 15)
        {
            rewardsstatus.text = "You just earned a water bottle! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "waterbottle")
        }
        if (prize >= 16 && prize <= 20)
        {
            amtleft = 21 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a T-shirt!"
            self.rewardimage.image = #imageLiteral(resourceName: "tshirt")
        }
        if (prize == 21)
        {
            rewardsstatus.text = "You just earned a t-shirt! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "tshirt")
        }
        if (prize >= 22 && prize <= 39)
        {
            amtleft = 40 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a sunglasses!"
            self.rewardimage.image = #imageLiteral(resourceName: "sunglasses")
        }
        if (prize == 40)
        {
            rewardsstatus.text = "You just earned a pair of sunglasses! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "sunglasses")
        }
        if (prize >= 41 && prize <= 59)
        {
            amtleft = 60 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a ball cap!"
            self.rewardimage.image = #imageLiteral(resourceName: "baseballcap")
        }
        if (prize == 60)
        {
            rewardsstatus.text = "You just earned a ball cap! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "baseballcap")
        }
        if (prize >= 61 && prize <= 79)
        {
            amtleft = 80 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a tote bag!"
            self.rewardimage.image = #imageLiteral(resourceName: "bag")
        }
        if (prize == 80)
        {
            rewardsstatus.text = "You just earned a tote bag! Go get it!"
            self.rewardimage.image = #imageLiteral(resourceName: "bag")
        }
        if (prize >= 81 && prize <= 99)
        {
            amtleft = 100 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 100)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 101 && prize <= 199)
        {
            amtleft = 200 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 200)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 201 && prize <= 299)
        {
            amtleft = 300 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 300)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 301 && prize <= 399)
        {
            amtleft = 400 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 400)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 401 && prize <= 499)
        {
            amtleft = 500 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 500)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 501 && prize <= 599)
        {
            amtleft = 600 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 600)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 601 && prize <= 699)
        {
            amtleft = 700 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 700)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 701 && prize <= 799)
        {
            amtleft = 800 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
             self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 800)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 801 && prize <= 899)
        {
            amtleft = 900 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 900)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize >= 901 && prize <= 999)
        {
            amtleft = 1000 - prize
            rewardsstatus.text = "You are " + String(amtleft) + " check ins away from earning a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
        if (prize == 1000)
        {
            rewardsstatus.text = "You just earned a free month of CrossFit!"
            self.rewardimage.image = #imageLiteral(resourceName: "barbell")
        }
    }
    
    func classruntotals()
    {
        var balance:String!
        var classmates:String!
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let todaysDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "yyyyMMdd_HH"
        let hour = dateFormatter.string(from: date)
        print(todaysDate)
        
        ref.child("class_running_total").queryOrdered(byChild: "date_class_hour").queryEqual(toValue: hour).observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
                self.class_running_total(data: [Constants.class_running_total.classmates: self.mUserLoggedIn], classmates: self.mUserLoggedIn, count: "1", date_class_hour: hour)
                return
            }
            else
            {
                for rest in Snap.children.allObjects as! [DataSnapshot] {
                    
                    guard let restDict = rest.value as? [String: Any] else { continue }
                    balance = restDict["count"] as! String
                    classmates = restDict["classmates"] as! String
                    classmates = classmates + "_" + self.mUserLoggedIn
                    var increase_count = Int(balance)
                    increase_count = increase_count! + 1
                    balance = String(describing: increase_count ?? 0)
                }
            }
            
            if let snapDict = Snap.value as? [String:AnyObject]{
                //     self.SignInRunningBalance(data: [Constants.SignInRunningBalance.username: self.mUserLoggedIn], lastupdated: todaysDate, balance: balance)
                for each in snapDict{
                    let key1 = (each.0)
                    let userRef = self.ref.child("class_running_total").child(key1)
                    userRef.updateChildValues(["count": balance])
                    userRef.updateChildValues(["classmates": classmates])
                }
                
            }
        })
    }
    
    func SignInRunningBalance(data: [String:String],lastupdated: String, balance: String, active:String, messagetoclient: String, timesthisweek: String, weekofyear: String, xaweek1: String) {
        var mdata = data
        mdata[Constants.SignInRunningBalance.last_updated] = lastupdated
        mdata[Constants.SignInRunningBalance.username] = mUserLoggedIn
        mdata[Constants.SignInRunningBalance.balance] = balance
        mdata[Constants.SignInRunningBalance.active] = active
        mdata[Constants.SignInRunningBalance.messagetoclient] = messagetoclient
        mdata[Constants.SignInRunningBalance.timesthisweek] = timesthisweek
        mdata[Constants.SignInRunningBalance.weekofyear] = weekofyear
        mdata[Constants.SignInRunningBalance.xaweek] = xaweek1
        ref.child("SignInRunningBalance").childByAutoId().setValue(mdata)
    }
    
    func SignIn(data: [String:String],balance_snap: String, date_checkin: String, date_hour: String, location: String, type: String  ) {
        var mdata = data
        mdata[Constants.SignIn.balance_snap] = balance_snap
        mdata[Constants.SignIn.date_checkin] = date_checkin
        mdata[Constants.SignIn.date_hour] = date_hour
        mdata[Constants.SignIn.location] = location
        mdata[Constants.SignIn.type] = type
        mdata[Constants.SignIn.username] = mUserLoggedIn

        ref.child("SignIn").childByAutoId().setValue(mdata)
    }
    
    func class_running_total(data: [String:String], classmates: String, count: String, date_class_hour: String) {
        var mdata = data
        // add name to message and then data to firebase database
        mdata[Constants.class_running_total.classmates] = classmates
        mdata[Constants.class_running_total.count] = count
        mdata[Constants.class_running_total.date_class_hour] = date_class_hour
        ref.child("class_running_total").childByAutoId().setValue(mdata)
    }
    
    func getaccesscode()
    {
        
        ref.child("qrcode").queryOrdered(byChild: "code").queryEqual(toValue: "valid").observeSingleEvent(of: .value, with: {(Snap) in
            
            if !Snap.exists() {
                // handle data not found
                return
            }
            else
            {
                for rest in Snap.children.allObjects as! [DataSnapshot] {
                    
                    guard let restDict = rest.value as? [String: Any] else { continue }
                    self.passcode = restDict["passcode"] as! String
                    print(self.passcode)
                }
            }
        })
    }
    

}
extension Date {
    func isInSameWeek(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }
    func isInSameMonth(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
    func isInSameYear(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }
    func isInSameDay(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
    var isInThisWeek: Bool {
        return isInSameWeek(date: Date())
    }
    var isInToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
}

