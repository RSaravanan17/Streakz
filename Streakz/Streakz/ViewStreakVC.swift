//
//  ViewStreakVC.swift
//  Streakz
//
//  Created by Zac Bonar on 3/22/21.
//

import UIKit

class ViewStreakVC: UIViewController {
    
    @IBOutlet weak var streakNumberDisplay: UILabel!
    @IBOutlet weak var subscribedDateDisplay: UILabel!
    @IBOutlet weak var buttonSubText: UILabel!
    @IBOutlet weak var markDoneButton: UIButton!
    @IBOutlet weak var streakTitleDisplay: UILabel!
    @IBOutlet weak var descriptionDisplay: UILabel!
    
    var curUserProfile: Profile? = nil
    var streakSub: StreakSubscription!
    
    var completeStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        streakTitleDisplay.text = streakSub.streakInfo.name
        streakNumberDisplay.text = String(streakSub.streakNumber)
        subscribedDateDisplay.text = streakSub.subscriptionStartDate.shortDate
        descriptionDisplay.text = streakSub.streakInfo.description
        
        if streakSub.canBeCompletedToday() {
            markDoneButton.isEnabled = true
            markDoneButton.setTitleColor(.systemBackground, for: .normal)
            markDoneButton.layer.borderWidth = 0.0
            markDoneButton.backgroundColor = UIColor(named: "Streakz_DarkRed")
            markDoneButton.setTitle("Mark done for today", for: .normal)

            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: streakSub.nextDeadline())
            let hoursRemaining = diffComponents.hour!
            let minutesRemaining = diffComponents.minute!
            
            var timeRemainingString: String = String(hoursRemaining) + " hours remaining"

            if hoursRemaining == 1 {
                timeRemainingString = String(hoursRemaining) + " hour remaining"
            } else if hoursRemaining == 0 {
                if minutesRemaining > 1 {
                    timeRemainingString = String(minutesRemaining) + " minutes remaining"
                } else if minutesRemaining == 1 {
                    timeRemainingString = String(minutesRemaining) + " minute remaining"
                } else {
                    timeRemainingString = "Less than a minute left!"
                }
            }
            
            buttonSubText.text = timeRemainingString
        } else {
            markDoneButton.isEnabled = false
            markDoneButton.setTitleColor(UIColor(named: "Streakz_DarkRed"), for: .normal)
            markDoneButton.layer.borderColor = UIColor(named: "Streakz_DarkRed")?.cgColor
            markDoneButton.layer.borderWidth = 1.0
            markDoneButton.backgroundColor = .systemBackground
            markDoneButton.setTitle("Complete", for: .normal)
            
            if streakSub.wasCompletedToday() {
                buttonSubText.text = "Good Job keeping up your streak today!"
            } else {
                buttonSubText.text = "Come back on " + streakSub.nextStreakDate().fullDate
            }
        }
        
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == completeStreakSegueIdentifier,
           let nextVC = segue.destination as? CompleteStreakVC
        {
            nextVC.streakSub = streakSub
            nextVC.curUserProfile = curUserProfile
        }
    }

}
