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
    
    var streakSub: StreakSubscription!
    
    var completeStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        streakNumberDisplay.text = String(streakSub.streakNumber)
        subscribedDateDisplay.text = streakSub.subscriptionStartDate.shortDate
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == completeStreakSegueIdentifier,
           let nextVC = segue.destination as? CompleteStreakVC
        {
            nextVC.streakSub = streakSub
        }
    }

}
