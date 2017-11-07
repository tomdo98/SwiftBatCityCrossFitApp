//
//  GymStore.swift
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

class GymStore: UIViewController, UINavigationControllerDelegate {
    var ref: DatabaseReference!
    var messages: [DataSnapshot]! = []
    fileprivate var _refHandle: DatabaseHandle!
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    var user: User?
    var displayName = "Anonymous"
    var mUserLoggedIn: String = ""
    
    @IBOutlet weak var StoreItemsTableView: UITableView!
    
    @IBOutlet weak var CellLabel: UILabel!
    override func viewDidLoad() {
        configureAuth()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
     //   unsubscribeFromAllNotifications()
    }
    
    func configureAuth() {
        let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        // listen for changes in the authorization state
        _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
            // refresh table data
            self.messages.removeAll(keepingCapacity: false)
            self.StoreItemsTableView.reloadData()
            
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
        _refHandle = ref.child("store").observe(.childAdded) { (snapshot: DataSnapshot)in
            self.messages.append(snapshot)
      //      print(self.messages)
            self.StoreItemsTableView.insertRows(at: [IndexPath(row: self.messages.count-1, section: 0)], with: .automatic)
          //  self.scrollToBottomMessage()
        }
    }
    
    deinit {
        ref.child("store").removeObserver(withHandle: _refHandle)
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    func signedInStatus(isSignedIn: Bool) {
        //signInButton.isHidden = isSignedIn
        //signOutButton.isHidden = !isSignedIn
        //messagesTable.isHidden = !isSignedIn
        //messageTextField.isHidden = !isSignedIn
        //sendButton.isHidden = !isSignedIn
        //imageMessage.isHidden = !isSignedIn
        //backgroundBlur.effect = UIBlurEffect(style: .light)
        
        if isSignedIn {
            // remove background blur (will use when showing image messages)
            //messagesTable.rowHeight = UITableViewAutomaticDimension
            //messagesTable.estimatedRowHeight = 122.0
            //backgroundBlur.effect = nil
            //messageTextField.delegate = self
            //subscribeToKeyboardNotifications()
            configureDatabase()
            //configureStorage()
            //configureRemoteConfig()
            //fetchConfig()
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
    
    
    
}

extension GymStore: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue cell
        let cell: UITableViewCell! = StoreItemsTableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        // unpack message from firebase data snapshot
        let messageSnapshot = messages[indexPath.row]
        let message = messageSnapshot.value as! [String: String]
     //   let name = message[Constants.MessageFields.name] ?? "[description]"
        // if image message, then grab image and display it
//        if let imageUrl = message[Constants.MessageFields.imageUrl] {
//            cell!.textLabel?.text = "sent by: \(name)"
            // image already exists in cache
//            if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {
//                cell.imageView?.image = cachedImage
//                cell.setNeedsLayout()
//            } else {
//                // download image
//                Storage.storage().reference(forURL: imageUrl).getData(maxSize: INT64_MAX, completion: { (data, error) in
//                    guard error == nil else {
//                        print("Error downloading: \(error!)")
//                        return
//                    }
//                    let messageImage = UIImage.init(data: data!, scale: 50)
//                    self.imageCache.setObject(messageImage!, forKey: imageUrl as NSString as NSString)
//                    // check if the cell is still on screen, if so, update cell image
//                    if cell == tableView.cellForRow(at: indexPath) {
//                        DispatchQueue.main.async {
//                            cell.imageView?.image = messageImage
//                            cell.setNeedsLayout()
//                        }
//                    }
//                })
//            }
//        } else {
//            // otherwise, update cell for regular message
            let text = message[Constants.store.description] ?? "[description]"
        let price = message[Constants.store.price] ?? "[price]"
            cell!.textLabel?.text = text
        cell!.detailTextLabel?.text = price
        
        if (text == "Knee Sleeves")
        {
            cell!.imageView?.image = #imageLiteral(resourceName: "kneesleeves")
        }
        if (text == "Fit Aid (1 can)")
        {
            cell!.imageView?.image = #imageLiteral(resourceName: "FitAid")
        }
        if (text == "T-Shirt or Tank")
        {
            cell!.imageView?.image = #imageLiteral(resourceName: "tshirt1")
        }
        if (text == "Water")
        {
            cell!.imageView?.image = #imageLiteral(resourceName: "fijiwater")
        }
        if (text == "Drop In")
        {
            cell!.imageView?.image = #imageLiteral(resourceName: "kb")
        }
        // cell!.textLabel?.text = price
                   
//            cell!.imageView?.image = placeholderImage
//        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        let todaysDate = dateFormatter.string(from: date)
        
        let cell = tableView.cellForRow(at: indexPath)
        print(cell!.textLabel?.text as Any)
        
        let refreshAlert = UIAlertController(title: "Confirm Purchase", message: "Are you sure you want to buy " + (cell!.textLabel?.text)!, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
           // print("Handle Ok logic here")
            self.purchases(data: [Constants.purchases.username : self.mUserLoggedIn], cost: (cell!.detailTextLabel?.text)!, datepurchased: todaysDate, items_purchased: (cell!.textLabel?.text)!)
            
            // create the alert
            let alert = UIAlertController(title: "Purchase complete", message: "Your purchase is complete. You will be charged " + (cell!.detailTextLabel?.text)! + " on your MindBody account on file.", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
          //  print("Handle Cancel Logic here")
            let alert = UIAlertController(title: "Purchase cancelled", message: "Selection cancelled.", preferredStyle: UIAlertControllerStyle.alert)
            
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
        

        // skip if keyboard is shown
     //   guard !messageTextField.isFirstResponder else { return }
        // unpack message from firebase data snapshot
     //   let messageSnapshot: DataSnapshot! = messages[(indexPath as NSIndexPath).row]
     //   let message = messageSnapshot.value as! [String: String]
        // if tapped row with image message, then display image
//        if let imageUrl = message[Constants.MessageFields.imageUrl] {
//            if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {
//                showImageDisplay(cachedImage)
//            } else {
//                Storage.storage().reference(forURL: imageUrl).getData(maxSize: INT64_MAX, completion: { (data, error) in
//                    guard error == nil else {
//                        print("Error downloading: \(error!)")
//                        return
//                    }
//                    self.showImageDisplay(UIImage.init(data: data!)!)
//                })
//            }
//        }
    }
    
    func purchases(data: [String:String],cost: String, datepurchased: String, items_purchased: String) {
        var mdata = data
        // add name to message and then data to firebase database
        mdata[Constants.purchases.cost] = cost
        mdata[Constants.purchases.datepurchased] = datepurchased
        mdata[Constants.purchases.items_purchased] = items_purchased
        mdata[Constants.purchases.username] = self.mUserLoggedIn
        ref.child("purchases").childByAutoId().setValue(mdata)
    }
}

