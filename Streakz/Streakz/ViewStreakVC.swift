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
    
    var streakSub: StreakSubscription!
    
    var completeStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        streakNumberDisplay.text = String(streakSub.streakNumber)
        subscribedDateDisplay.text = streakSub.subscriptionStartDate.shortDate
        
        if streakSub.wasCompletedToday() {
            markDoneButton.isEnabled = false
            buttonSubText.text = "Good Job keeping up your streak today!"
        } else if streakSub.canBeCompletedToday() {
            markDoneButton.isEnabled = true

            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: streakSub.nextDeadline())
            // TODO: what if less than 1 hour remains
            let timeRemainingString = String(diffComponents.hour!) + " hours remaining"
            
            buttonSubText.text = timeRemainingString
        } else {
            // TODO: style button differently if disabled
            markDoneButton.isEnabled = false
            buttonSubText.text = "Can't do streak today"
        }
        
        
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == completeStreakSegueIdentifier,
           let nextVC = segue.destination as? CompleteStreakVC
        {
            nextVC.streakSub = streakSub
        }
    }

}
