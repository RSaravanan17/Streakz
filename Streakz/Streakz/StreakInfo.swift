//
//  Streak.swift
//  Streakz
//
//  Created by John Cauvin on 3/18/21.
//

import Foundation

class StreakInfo : Codable {
    
    let owner: [String]
    var name: String
    var description: String
    var reminderDays: [Bool]       // 0th index is Sunday, 1st is Monday, etc.
    var subscribers: [BaseProfile]
    var viewability: StreakSubscription.PrivacyType
    
    init(owner: [String], name: String, description: String, reminderDays: [Bool], viewability: StreakSubscription.PrivacyType) {
        self.owner = owner
        self.name = name
        self.description = description
        self.reminderDays = reminderDays
        self.subscribers = []
        self.viewability = viewability
    }
}
