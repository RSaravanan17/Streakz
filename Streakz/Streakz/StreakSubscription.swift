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
    
    // if streakExpired() is true, then resetStreak() must be called
    func streakExpired() -> Bool {
        let expiryDate = lastStreakUpdate
        
        let calendar = Calendar.current
        
        func incrementDayInt(day: Int) -> Int {
            var d = day
            d += 1
            if (d == 8) {
                d = 1
            }
            return d
        }
        
        var nextStreakDay = calendar.component(.weekday, from: expiryDate) // 1 is Sunday, ..., 7 is Saturday
        nextStreakDay = incrementDayInt(day: nextStreakDay)

        while (!streakInfo.reminderDays[nextStreakDay - 1]) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }

        let nextStreakDeadlineDay = incrementDayInt(day: nextStreakDay)

        let nextStreakDeadlineComponents = DateComponents(calendar:calendar, weekday: nextStreakDeadlineDay)
        let afterDate = calendar.date(byAdding: .day, value: 1, to: expiryDate)!
        let nextDeadlineDate = calendar.nextDate(after: afterDate, matching: nextStreakDeadlineComponents, matchingPolicy: .nextTime)!
        
        return streakNumber != 0 && nextDeadlineDate < Date()
    }
    
    // Returns the next deadline from today
    func nextDeadline() -> Date {
        //pre-condition needed to avoid infinite loop due to bad data
        assert(streakInfo.reminderDays.contains(true))
        
        let today = Date()

        let calendar = Calendar.current
        
        func incrementDayInt(day: Int) -> Int {
            var d = day
            d += 1
            if (d == 8) {
                d = 1
            }
            return d
        }
        
        var nextStreakDay = calendar.component(.weekday, from: today) // 1 is Sunday, ..., 7 is Saturday

        if (!canBeCompletedToday()) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }

        while (!streakInfo.reminderDays[nextStreakDay - 1]) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }

        let nextStreakDeadlineDay = incrementDayInt(day: nextStreakDay)

        let nextStreakDeadlineComponents = DateComponents(calendar:calendar, weekday: nextStreakDeadlineDay)
        let afterDate = !canBeCompletedToday() ? calendar.date(byAdding: .day, value: 1, to: today)! : today

        let nextDeadlineDate = calendar.nextDate(after: afterDate, matching: nextStreakDeadlineComponents, matchingPolicy: .nextTime)!

        return nextDeadlineDate
    }
    
    func canBeCompletedToday() -> Bool {
        let calendar = Calendar.current
        
        let weekdayToday = calendar.component(.weekday, from: Date()) // 1 is Sunday, ..., 7 is Saturday
        let streakDayToday = streakInfo.reminderDays[weekdayToday - 1]
        
        return streakDayToday && !wasCompletedToday()
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
