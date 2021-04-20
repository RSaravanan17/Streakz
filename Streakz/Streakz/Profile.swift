//
//  Profile.swift
//  Streakz
//
//  Created by John Cauvin on 3/18/21.
//

import Foundation

class Profile : Codable {
    
    var firstName: String
    var lastName: String
    var profilePicture: String = "" // set this to link to some default profile picture
    var friends: [BaseProfile] = []
    var friendRequests: [BaseProfile] = []
    var subscribedStreaks: [StreakSubscription] = []
    var streakPosts: [StreakPost] = []
    var finalReminderTime: Date?
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}
