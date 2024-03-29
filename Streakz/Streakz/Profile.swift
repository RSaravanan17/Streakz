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
    var profilePicture: String = ""
    var friends: [BaseProfile] = []
    var friendRequests: [BaseProfile] = []
    var subscribedStreaks: [StreakSubscription] = []
    var streakPosts: [StreakPost] = []
    var finalReminderTime: Date?
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
    
    func getBasicFriendsList() -> [[String]] {
        var friendsBasic: [[String]] = []
        for friend in self.friends {
            friendsBasic.append([friend.email, friend.profileType])
        }
        return friendsBasic
    }
}
