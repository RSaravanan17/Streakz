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

            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: streakSub.nextDeadline())
            // TODO: what if less than 1 hour remains
            let timeRemainingString = String(diffComponents.hour!) + " hours remaining"
            
            buttonSubText.text = timeRemainingString
        } else {
            // TODO: style button differently if disabled
            markDoneButton.isEnabled = false
            
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
