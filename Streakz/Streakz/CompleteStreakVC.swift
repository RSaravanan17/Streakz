//
//  CompleteStreakVC.swift
//  Streakz
//
//  Created by Zac Bonar on 3/23/21.
//

import UIKit

class CompleteStreakVC: UIViewController, UITextViewDelegate {

    @IBOutlet weak var streakTitleLabel: UILabel!
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var oldStreakNumberLabel: UILabel!
    @IBOutlet weak var newStreakNumberLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    let commentPlaceholder = "Comment on your latest streak achievement"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    
    var streakSub: StreakSubscription!
    var curUserProfile: Profile? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        commentTextView.delegate = self
        commentTextView.text = commentPlaceholder
        commentTextView.textColor = textFieldGray

        // make description text view match name text field
        commentTextView.layer.cornerRadius = 5
        commentTextView.layer.borderColor = textFieldGray.cgColor
        commentTextView.layer.borderWidth = 0.5
        commentTextView.clipsToBounds = true
        
        streakTitleLabel.text = streakSub.streakInfo.name
        currentDateLabel.text = Date().fullDate
        oldStreakNumberLabel.text = String(streakSub.streakNumber)
        newStreakNumberLabel.text = String(streakSub.streakNumber + 1)
    }
    
    @IBAction func postStreakPressed(_ sender: Any) {
        _ = streakSub.completeStreak()
        // TODO: let user add images to post
        let postText = commentTextView.text ?? "Streak completed!"
        let streakPost = StreakPost(for: streakSub, postText: postText, image: "")
        
        if let curProfile = curUserProfile {
            // update firebase
            curProfile.streakPosts.append(streakPost)
            do {
                try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: curProfile)
            } catch let error {
                print("Error writing profile to Firestore: \(error)")
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if commentTextView.textColor == textFieldGray {
            commentTextView.text = nil
            commentTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if commentTextView.text.isEmpty {
            commentTextView.text = commentPlaceholder
            commentTextView.textColor = textFieldGray
        }
    }

}
