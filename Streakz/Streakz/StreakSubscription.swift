//
//  SubscribedStreak.swift
//  Streakz
//
//  Created by John Cauvin on 3/19/21.
//

import Foundation


/*
 could have substreak inherit from streak as they will share some properties like name, owner, etc.
 
 subscribed streak will need:
 counter
 subscription start date
 frequency information for notifications
 
 */

/*
 StreakSubscription objects keep track statistics for a user's currently active streak.
 StreakSubscriptions inherit from StreakInfo, so they still contain the information about a streak.
 */
class StreakSubscription {
    /*
     constructor takes in a streakinfo class so that we can add the user to streakinfo list of subscribers
     
     <inherited properties>
     
     streak number/counter (int >=0)
     reminder information. a date/calendar class to remind user to do streak in addition to final streak notification
     subscription start date
     streak privacy setting: public/private/friend's only (applies to posts and whether or not it displays on your profile)
     */
    
    enum PrivacyType {
        case Private, Friends, Public
    }
    
    var streakNumber: Int
    var reminderTime: Date
    var subscriptionStartDate: Date
    var privacy: PrivacyType
    var streakInfo: StreakInfo
    
    init(streakInfo: StreakInfo, reminderTime: Date, subscriptionStartDate: Date, privacy: PrivacyType) {
        self.streakInfo = streakInfo
        self.streakNumber = 0
        self.reminderTime = reminderTime
        self.subscriptionStartDate = subscriptionStartDate
        self.privacy = privacy
    }
}
