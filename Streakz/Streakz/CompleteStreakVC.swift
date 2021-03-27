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
    var curUserProfile: Profile? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        streakTitleLabel.text = streakSub.streakInfo.name
        currentDateLabel.text = Date().fullDate
        oldStreakNumberLabel.text = String(streakSub.streakNumber)
        newStreakNumberLabel.text = String(streakSub.streakNumber + 1)
    }
    
    @IBAction func postStreakPressed(_ sender: UIButton) {
        // TODO: create streak post
        _ = streakSub.completeStreak()
        
        if let curProfile = curUserProfile {
            // update firebase
            do {
                try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: curProfile)
            } catch let error {
                print("Error writing profile to Firestore: \(error)")
            }
        }
        
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
