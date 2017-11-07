//
//  Constants.swift
//  BatCityCrossFit
//
//  Created by Tommy Do on 9/17/17.
//  Copyright © 2017 Tommy Do. All rights reserved.
//

import Foundation
struct Constants {
    
    // MARK: NotificationKeys
    
    struct NotificationKeys {
        static let SignedIn = "onSignInCompleted"
    }
    
    // MARK: MessageFields
    
    struct MessageFields {
        static let name = "name"
        static let text = "text"
    //    static let imageUrl = "photoUrl"
    }
    
    struct class_running_total {
        static let classmates = "classmates"
        static let count = "count"
        static let date_class_hour = "date_class_hour"
    }
    
    struct card_stat {
        static let last_updated = "last_updated"
        static let stat_type = "stat_type"
        static let username = "username"
    }
    
    struct SignIn {
        static let balance_snap = "balance_snap"
        static let date_checkin = "date_checkin"
        static let date_hour = "date_hour"
        static let location = "location"
        static let type = "type"
        static let username = "username"
    }
    
    struct SignInRunningBalance {
        static let balance = "balance"
        static let last_updated = "last_updated"
        static let username = "username"
        static let active = "active"
        static let messagetoclient = "messagetoclient"
        static let timesthisweek = "timesthisweek"
        static let weekofyear = "weekofyear"
        static let xaweek = "xaweek"
    }
    
    struct store {
        static let description = "description"
        static let image = "image"
        static let item = "item"
        static let price = "price"
    }
    
    struct purchases {
        static let cost = "cost"
        static let datepurchased = "datepurchased"
        static let items_purchased = "items_purchased"
        static let username = "username"
    }
    
    struct batcitycomments {
        static let comment = "comment"
        static let datecomment = "datecomment"
        static let username = "username"
    }
    
    struct oly_punch_cards {
        static let last_updated = "last_updated"
        static let punchesleft = "punchesleft"
        static let username = "username"
    }
    struct punch_cards {
        static let last_updated = "last_updated"
        static let punchesleft = "punchesleft"
        static let username = "username"
    }
    struct cardio_punch_cards {
        static let last_updated = "last_updated"
        static let punchesleft = "punchesleft"
        static let username = "username"
    }
    

}
