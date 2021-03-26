//
//  SubscribedStreak.swift
//  Streakz
//
//  Created by John Cauvin on 3/19/21.
//

import Foundation

/*
 StreakSubscription objects keep track statistics for a user's currently active streak.
 StreakSubscriptions will store a StreakInfo object, so they still contain the information about a streak.
 */
class StreakSubscription : Codable {
    
    enum PrivacyType : String, Codable {
        case Private, Friends, Public
    }
    
    var streakNumber: Int
    var reminderTime: Date
    var subscriptionStartDate: Date
    var privacy: PrivacyType
    var streakInfo: StreakInfo
    var lastStreakUpdate: Date
    
    init(streakInfo: StreakInfo, reminderTime: Date, subscriptionStartDate: Date, privacy: PrivacyType) {
        self.streakInfo = streakInfo
        self.streakNumber = 0
        self.reminderTime = reminderTime
        self.subscriptionStartDate = subscriptionStartDate
        self.privacy = privacy
        self.lastStreakUpdate = .distantPast // This helps us know that this streak has never been completed
    }
    
    func nextDeadline() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        
        func getNextDayInt(day: Int) -> Int {
            var d = day
            d += 1
            if (d == 8) {
                d = 1
            }
            return d
        }
        
        let currentDay = calendar.component(.weekday, from: currentDate) // 1 is Sunday, ..., 7 is Saturday
        var nextStreakDay = currentDay

        if (streakWasCompletedToday()) {
            nextStreakDay = getNextDayInt(day: nextStreakDay)
        }
        
        //avoiding infinite loop due to bad data
        assert(streakInfo.reminderDays.contains(true))
        
        while (!streakInfo.reminderDays[nextStreakDay - 1]) {
            nextStreakDay = getNextDayInt(day: nextStreakDay)
        }
        
        let nextStreakDeadline = getNextDayInt(day: nextStreakDay)

        let nextStreakDeadlineComponents = DateComponents(calendar:calendar, weekday: nextStreakDeadline)
        
        let nextDeadline = calendar.nextDate(after: currentDate, matching: nextStreakDeadlineComponents, matchingPolicy: .nextTime)!
        print("\n\nStreak:", streakInfo.name, "next deadline is:", nextDeadline.fullDateTime)
        
        return nextDeadline
    }
    
    func canBeCompletedToday() -> Bool {
        let calendar = Calendar.current
        // Deadline is midnight tomorrow, so if deadline is tomorrow then streak must be done today
        return calendar.isDateInTomorrow(nextDeadline())
    }
    
    func streakWasCompletedToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(lastStreakUpdate)
    }
    
    // Increments this StreakSubscription's counter by 1
    // Returns true if successful, false otherwise
    func completeStreak() -> Bool {
        if (canBeCompletedToday()) {
            streakNumber += 1
            lastStreakUpdate = Date()
            return true
        }
        return false
    }
    
    
}
