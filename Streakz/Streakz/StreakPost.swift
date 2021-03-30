//
//  StreakPost.swift
//  Streakz
//
//  Created by John Cauvin on 3/19/21.
//

import Foundation

/*
 Class to store information about a streak post
 */

class StreakPost : Codable {

    var streak: StreakSubscription
    var postText: String
    var image: String
    var datePosted: Date
    var achievedStreak: Int
    
    init(for streak: StreakSubscription, postText: String, image: String) {
        self.streak = streak
        self.postText = postText
        self.image = image
        // capture current date for when post was made
        datePosted = Date()
        // achieved streak is the streak number accomplished when the post is created
        achievedStreak = streak.streakNumber
    }
}
