//
//  BaseProfile.swift
//  Streakz
//
//  Created by Zac Bonar on 3/26/21.
//

import UIKit

class BaseProfile: Codable, Hashable {
    
    var profileType: String // profiles_email, profiles_google, or profiles_facebook
    var email: String
    
    init(profileType: String, email: String) {
        self.profileType = profileType
        self.email = email
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(profileType)
        hasher.combine(email)
    }
    
    static func == (lhs: BaseProfile, rhs: BaseProfile) -> Bool {
        return (lhs.email == rhs.email) && (rhs.profileType == rhs.profileType)
    }
}
