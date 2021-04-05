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
        case Private
        case Friends
        case Public
    }
    
    var streakNumber: Int
    var reminderTime: Date
    var subscriptionStartDate: Date
    var privacy: PrivacyType
    var streakInfoId: String
    var lastStreakUpdate: Date
    var reminderDays: [Bool]
    var name: String
    
    enum StreakSubscriptionError: Error {
        case invalidStreakId
    }
    
    init(streakInfoId: String, reminderTime: Date, subscriptionStartDate: Date, privacy: PrivacyType, reminderDays: [Bool], name: String) {
        self.streakInfoId = streakInfoId
        self.streakNumber = 0
        self.reminderTime = reminderTime
        self.subscriptionStartDate = subscriptionStartDate
        self.privacy = privacy
        self.lastStreakUpdate = Date()
        self.reminderDays = reminderDays
        self.name = name
    }
    
    // Creates a listener for this streak's StreakInfo object in the database
    // callback is ran whenever the streakInfo is updated
    func listenStreakInfo(callback: @escaping (StreakInfo?) -> Void) {
        var collection = "private_streaks"
        if privacy == .Friends {
            collection = "friends_streaks"
        } else if privacy == .Public {
            collection = "public_streaks"
        }
        
        db_firestore.collection(collection).document(streakInfoId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching StreakInfo: \(error!)")
                    return
                }
                guard document.data() != nil else {
                    print("StreakInfo fetch - document data was empty.")
                    return
                }
                do {
                    let streakInfo = try document.data(as: StreakInfo.self)
                    print("StreakInfo successfully fetched")
                    callback(streakInfo)
                } catch let error {
                    print("Error deserializing StreakInfo data", error)
                }
        }
    }
    
    // Returns the next deadline from today
    func nextDeadline() -> Date {
        return nextDeadlineFromDate(startDate: Date(), needsToBeCompletedOnThatDate: canBeCompletedToday())
    }
    
    // if streakExpired() is true, then resetStreak() must be called
    func streakExpired() -> Bool {
        let expiryDate = nextDeadlineFromDate(startDate: lastStreakUpdate, needsToBeCompletedOnThatDate: false)
        
        return streakNumber != 0 && expiryDate < Date()
    }
    
    // Helper function used by nextDeadline and streakExpired
    private func nextDeadlineFromDate(startDate: Date, needsToBeCompletedOnThatDate: Bool) -> Date {
        //pre-condition needed to avoid infinite loop due to bad data
        assert(reminderDays.contains(true))

        let calendar = Calendar.current
        
        func incrementDayInt(day: Int) -> Int {
            var d = day
            d += 1
            if (d == 8) {
                d = 1
            }
            return d
        }
        
        var nextStreakDay = calendar.component(.weekday, from: startDate) // 1 is Sunday, ..., 7 is Saturday

        if (!needsToBeCompletedOnThatDate) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }

        while (!reminderDays[nextStreakDay - 1]) {
            nextStreakDay = incrementDayInt(day: nextStreakDay)
        }

        let nextStreakDeadlineDay = incrementDayInt(day: nextStreakDay)

        let nextStreakDeadlineComponents = DateComponents(calendar:calendar, weekday: nextStreakDeadlineDay)
        let afterDate = !needsToBeCompletedOnThatDate ? calendar.date(byAdding: .day, value: 1, to: startDate)! : startDate

        let nextDeadlineDate = calendar.nextDate(after: afterDate, matching: nextStreakDeadlineComponents, matchingPolicy: .nextTime)!

        return nextDeadlineDate
    }
    
    func canBeCompletedToday() -> Bool {
        let calendar = Calendar.current
        
        let weekdayToday = calendar.component(.weekday, from: Date()) // 1 is Sunday, ..., 7 is Saturday
        let streakDayToday = reminderDays[weekdayToday - 1]
        
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
