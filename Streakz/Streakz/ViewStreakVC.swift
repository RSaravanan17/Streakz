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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        streakNumberDisplay.text = String(streakSub.streakNumber)
        
        subscribedDateDisplay.text = streakSub.subscriptionStartDate.shortDate
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
