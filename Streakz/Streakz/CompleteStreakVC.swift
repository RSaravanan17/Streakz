//
//  CompleteStreakVC.swift
//  Streakz
//
//  Created by Zac Bonar on 3/23/21.
//

import UIKit

class CompleteStreakVC: UIViewController {

    @IBOutlet weak var streakTitleLabel: UILabel!
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var oldStreakNumberLabel: UILabel!
    @IBOutlet weak var newStreakNumberLabel: UILabel!
    
    var streakSub: StreakSubscription!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        streakTitleLabel.text = streakSub.streakInfo.name
        currentDateLabel.text = Date().fullDate
        oldStreakNumberLabel.text = String(streakSub.streakNumber)
        newStreakNumberLabel.text = String(streakSub.streakNumber + 1)
    }
    
    @IBAction func postStreakPressed(_ sender: UIButton) {
        // TODO: create streak post and properly update this StreakSubscription
        streakSub.streakNumber += 1
        navigationController?.popViewController(animated: true)
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
