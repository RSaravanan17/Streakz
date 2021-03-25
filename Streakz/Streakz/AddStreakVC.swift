//
//  AddStreakVC.swift
//  Streakz
//
//  Created by John Cauvin on 3/21/21.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class AddStreakVC: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    // outlets
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addStreakButton: UIButton!
    @IBOutlet weak var viewSunday: UIView!
    @IBOutlet weak var viewMonday: UIView!
    @IBOutlet weak var viewTuesday: UIView!
    @IBOutlet weak var viewWednesday: UIView!
    @IBOutlet weak var viewThursday: UIView!
    @IBOutlet weak var viewFriday: UIView!
    @IBOutlet weak var viewSaturday: UIView!
    @IBOutlet weak var reminderTimePicker: UIDatePicker!
    @IBOutlet weak var visibilityPicker: UIPickerView!
    
    var daysOfWeekViews: [UIView?] = []
    var daysOfWeekButtons: [UIButton] = []
    let daysOfWeekTitles = ["Su", "M", "Tu", "W", "Th", "F", "Sa"]
    var daysOfWeekSelected = [false, false, false, false, false, false, false]
    var curUserProfile: Profile? = nil
    let descPlaceholder = "Do push ups three times a week for the gains"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let collection = cur_user_collection, let document = cur_user_email {
            db_firestore.collection(collection).document(document).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    if let fetchedProfile = fetchedProfile {
                        print("Received profile successfully")
                        self.curUserProfile = fetchedProfile
                    } else {
                        print("Document doesn't exist")
                    }
                case .failure(let error):
                    print("Error decoding document into profile: \(error)")
                }
            }
        } else {
            print("Error fetching current profile - user email and/or profile_type is nil")
        }
        
        visibilityPicker.dataSource = self
        visibilityPicker.delegate = self
        
        descTextView.delegate = self
        descTextView.text = descPlaceholder
        descTextView.textColor = textFieldGray

        // make description text view match name text field
        descTextView.layer.cornerRadius = 5
        descTextView.layer.borderColor = textFieldGray.cgColor
        descTextView.layer.borderWidth = 0.5
        descTextView.clipsToBounds = true
        
        daysOfWeekViews = [
            viewSunday,
            viewMonday,
            viewTuesday,
            viewWednesday,
            viewThursday,
            viewFriday,
            viewSaturday
        ]
        
        // Testing for button
        for (i, view) in daysOfWeekViews.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            button.backgroundColor = UIColor.gray
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            button.setTitle(daysOfWeekTitles[i], for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.addTarget(self, action: #selector(dayPressed), for: .touchUpInside)
            daysOfWeekButtons.append(button)
            view?.addSubview(button)
        }
    }
    
    @objc func dayPressed(sender: UIButton!) {
        let index = daysOfWeekTitles.firstIndex(of: sender.title(for: .normal)!)!
        daysOfWeekSelected[index] = !daysOfWeekSelected[index]
        if daysOfWeekSelected[index] {
            daysOfWeekButtons[index].backgroundColor = UIColor.init(named: "Streakz_DarkRed")
        } else {
            daysOfWeekButtons[index].backgroundColor = UIColor.gray
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 3
        } else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "Only Me"
        } else if component == 1 {
            return "Friends"
        } else {
            return "Anyone"
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descTextView.textColor == textFieldGray {
            descTextView.text = nil
            descTextView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descTextView.text.isEmpty {
            descTextView.text = descPlaceholder
            descTextView.textColor = textFieldGray
        }
    }
    
    @IBAction func addStreakPressed(_ sender: Any) {
        if let streakName = nameTextField.text,
           let streakDesc = descTextView.text,
           let owner = cur_user_email,
           let collection = cur_user_collection,
           let curProfile = curUserProfile,
           !daysOfWeekSelected.allSatisfy({$0 == false}) {
            let newStreak = StreakInfo(owner: owner, name: streakName, description: streakDesc, reminderDays: daysOfWeekSelected)
            
            // autosubscribe the user
            let subbedStreak = StreakSubscription(streakInfo: newStreak, reminderTime: reminderTimePicker.date, subscriptionStartDate: Date(), privacy: .Private)
            
            // add to user's profile streaks profile list
            newStreak.subscribers.append(cur_user_profile!)
            
            // add streak to user profile
            curProfile.subscribedStreaks.append(subbedStreak)
            
            // if streak privacy is public, add to collection of public streaks
            
            // update firebase
            do {
                print("Attempting to add streak for", cur_user_email!, "in", cur_user_collection!)
                try db_firestore.collection(collection).document(owner).setData(from: curProfile)
            } catch let error {
                print("Error writing profile to Firestore: \(error)")
            }
        } else {
            
        }
    }
}
