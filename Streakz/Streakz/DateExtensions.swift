//
//  DateExtensions.swift
//  Streakz
//
//  Created by Zac Bonar on 3/22/21.
//

// Swift offers very little help formatting dates natively, so these extensions should help
// Credit to https://stackoverflow.com/a/28347285/2303865

// Example Usage:
//
// Date().fullDate  // "Friday, May 26, 2017\n"
// Date().shortDate  // "5/26/17\n"
// Date().fullTime  // "10:16:24 AM Brasilia Standard Time\n"
// Date().shortTime  // "10:16 AM\n"
// Date().fullDateTime  // "Friday, May 26, 2017 at 10:16:24 AM Brasilia Standard Time\n"
// Date().shortDateTime  // "5/26/17, 10:16 AM\n"

import UIKit

extension TimeZone {
    static let gmt = TimeZone(secondsFromGMT: 0)!
}
extension Formatter {
    static let date = DateFormatter()
}

extension Date {
    func localizedDescription(dateStyle: DateFormatter.Style = .medium,
                              timeStyle: DateFormatter.Style = .medium,
                           in timeZone : TimeZone = .current,
                              locale   : Locale = .current) -> String {
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
    var localizedDescription: String { localizedDescription() }
}

extension Date {

    var fullDate: String   { localizedDescription(dateStyle: .full,   timeStyle: .none) }
    var longDate: String   { localizedDescription(dateStyle: .long,   timeStyle: .none) }
    var mediumDate: String { localizedDescription(dateStyle: .medium, timeStyle: .none) }
    var shortDate: String  { localizedDescription(dateStyle: .short,  timeStyle: .none) }

    var fullTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .full) }
    var longTime: String   { localizedDescription(dateStyle: .none,   timeStyle: .long) }
    var mediumTime: String { localizedDescription(dateStyle: .none,   timeStyle: .medium) }
    var shortTime: String  { localizedDescription(dateStyle: .none,   timeStyle: .short) }

    var fullDateTime: String   { localizedDescription(dateStyle: .full,   timeStyle: .full) }
    var longDateTime: String   { localizedDescription(dateStyle: .long,   timeStyle: .long) }
    var mediumDateTime: String { localizedDescription(dateStyle: .medium, timeStyle: .medium) }
    var shortDateTime: String  { localizedDescription(dateStyle: .short,  timeStyle: .short) }
}
