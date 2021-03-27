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
        self.lastStreakUpdate = Date()
    }
    
    // Returns a Date that represents when this streak expires
    // if nextDeadline() is in the past, that means this streak has been expired, and resetStreak() should be called
    func nextDeadline() -> Date {
        //pre-condition needed to avoid infinite loop due to bad data
        assert(streakInfo.reminderDays.contains(true))
        
        let calendar = Calendar.current
        
        func incrementDayInt(day: Int) -> Int {
            var d = day
            d += 1
            if (d == 8) {
                d = 1
            }
            return d
        }
        
        let lastDayUpdated = calendar.component(.weekday, from: lastStreakUpdate) // 1 is Sunday, ..., 7 is Saturday
        var nextStreakDay = lastDayUpdated

        if (wasCompletedToday()) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }
        
        while (!streakInfo.reminderDays[nextStreakDay - 1]) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }
        
        let nextStreakDeadlineDay = incrementDayInt(day: nextStreakDay)
        let nextStreakDeadlineComponents = DateComponents(calendar:calendar, weekday: nextStreakDeadlineDay)
        let afterDate = wasCompletedToday() ? calendar.date(byAdding: .day, value: 1, to: lastStreakUpdate)! : lastStreakUpdate
        let nextDeadlineDate = calendar.nextDate(after: afterDate, matching: nextStreakDeadlineComponents, matchingPolicy: .nextTime)!
        
        return nextDeadlineDate
    }
    
    func canBeCompletedToday() -> Bool {
        let calendar = Calendar.current
        // Deadline is midnight tomorrow, so if deadline is tomorrow then streak must be done today
        return calendar.isDateInTomorrow(nextDeadline())
    }
    
    func wasCompletedToday() -> Bool {
        let calendar = Calendar.current
        
        return streakNumber != 0 && calendar.isDateInToday(lastStreakUpdate)
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
    
    func nextStreakDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: nextDeadline())!
    }
    
    func resetStreak() {
        streakNumber = 0
        lastStreakUpdate = Date()
    }
}
