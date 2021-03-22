//
//  Streak.swift
//  Streakz
//
//  Created by John Cauvin on 3/18/21.
//

import Foundation

class StreakInfo : Codable {
    /*
     contains the information about the streak such as:
     owner
     description
     name
     frequency (days of week) is consistent across everyone. reminder customization is done through settings "final reminder" setting or streaksubscription-specific reminder
     subscribers/members
     viewability: public/private/friend's only
     */
    
    let owner: String
    var name: String
    var description: String
    var frequency: String
    var subscribers: [Profile]
    var viewability: String
    
    init(owner: String, name: String, description: String) {
        self.owner = owner
        self.name = name
        self.description = description
        self.frequency = ""
        self.subscribers = [Profile(firstName: "Test", lastName: "User")]
        self.viewability = ""
    }
}
