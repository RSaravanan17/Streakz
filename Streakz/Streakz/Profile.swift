//
//  Profile.swift
//  Streakz
//
//  Created by John Cauvin on 3/18/21.
//

import Foundation

class Profile : Codable {
    /*
     First name
     last name
     Profile picture (link)
     Friend's list
     List of subscribed streaks List<StreakSubscription> (length of it == active streaks number)
     List of streak posts
     */
    
    let firstName: String
    var lastName: String
    var profilePicture: String = "" // set this to link to some default profile picture
    var friends: [Profile] = []
    var subscribedStreaks: [StreakSubscription] = []
    var streakPosts: [StreakPost] = []
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}
