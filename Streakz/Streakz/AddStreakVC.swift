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
    @IBOutlet weak var visibilityLabel: UILabel!
    
    var pickerData: [StreakSubscription.PrivacyType] = [.Private, .Friends, .Public]
    var privacyType: StreakSubscription.PrivacyType!
    
    var daysOfWeekViews: [UIView?] = []
    var daysOfWeekButtons: [UIButton] = []
    let daysOfWeekTitles = ["Su", "M", "Tu", "W", "Th", "F", "Sa"]
    var daysOfWeekSelected = [false, false, false, false, false, false, false]
    var curUserProfile: Profile? = nil
    let descPlaceholder = "Enter Streak Description"
    let textFieldGray = UIColor.gray.withAlphaComponent(0.5)
    var userIsEditing: Bool = false         // false if user is creating a new streak, true if simply editing
    var editStreakInfoId: String? = nil     // if this is an edit, need streakInfoId to update in firebase
    var editStreakInfo: StreakInfo? = nil   // if this is an edit, need streakInfo object to update firebase
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        privacyType = self.pickerData[0]
        
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
        
        if userIsEditing, let streakInfoId = editStreakInfoId {
            addStreakButton.setTitle("Save", for: .normal)
            descTextView.textColor = .label
            descTextView.text = "Loading Description..."
            nameTextField.text = "Loading Name..."
            visibilityPicker.isHidden = true
            visibilityLabel.isHidden = true
            db_firestore.collection("private_streaks").document(streakInfoId).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: StreakInfo.self)
                }
                switch result {
                case .success(let fetchedStreakInfo):
                    self.editStreakInfo = fetchedStreakInfo
                    self.descTextView.text = fetchedStreakInfo?.description
                    self.nameTextField.text = fetchedStreakInfo?.name
                case .failure(let error):
                    print("Error fetching streakInfo on edit streak screen: \(error)")
                }
                
            }
        }
        
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
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            button.backgroundColor = daysOfWeekSelected[i] ? UIColor.init(named: "Streakz_DarkRed") : UIColor.gray
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
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        privacyType = pickerData[row]
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descTextView.textColor == textFieldGray {
            descTextView.text = nil
            descTextView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descTextView.text.isEmpty {
            descTextView.text = descPlaceholder
            descTextView.textColor = textFieldGray
        }
    }
    
    @IBAction func addStreakPressed(_ sender: Any) {
        /* Begin Input Verification */
        guard let streakName = nameTextField.text,
              !streakName.isEmpty
        else {
            let alert = UIAlertController(
                title: "Streak Incomplete",
                message: "Please fill out a Streak Name",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard let streakDesc = descTextView.text,
              !streakDesc.isEmpty && streakDesc != descPlaceholder
        else {
            let alert = UIAlertController(
                title: "Streak Incomplete",
                message: "Please fill out a valid Streak Description",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard !daysOfWeekSelected.allSatisfy({$0 == false}) else {
            let alert = UIAlertController(
                title: "Streak Incomplete",
                message: "Please select at least one day for when this streak should be completed",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard let email = cur_user_email,
              let collection = cur_user_collection,
              let curProfile = curUserProfile
        else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        /* End Input Verification */
        
        if userIsEditing {
            // user is editing an existing streak
            
            if let streakInfoId = editStreakInfoId,
               let streakInfo = editStreakInfo,
               let idx = curProfile.subscribedStreaks.firstIndex(where: { $0.streakInfoId == editStreakInfoId }) {
                
                if daysOfWeekSelected != streakInfo.reminderDays {
                    let alert = UIAlertController(
                        title: "Reminder days changed",
                        message: "Changing the reminder days will reset your streak. Are you sure you want to continue?",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {_ in
                        curProfile.subscribedStreaks[idx].resetStreak()
                        self.persistEditToFirestore(streakInfo: streakInfo,
                                               streakName: streakName,
                                               streakDesc: streakDesc,
                                               curProfile: curProfile,
                                               idx: idx,
                                               streakInfoId: streakInfoId,
                                               collection: collection,
                                               email: email)
                        self.navigationController?.popViewController(animated: true)
                    } ))
                    present(alert, animated: true, completion: nil)
                } else {
                    persistEditToFirestore(streakInfo: streakInfo,
                                           streakName: streakName,
                                           streakDesc: streakDesc,
                                           curProfile: curProfile,
                                           idx: idx,
                                           streakInfoId: streakInfoId,
                                           collection: collection,
                                           email: email)
                    navigationController?.popViewController(animated: true)
                }
            }
        } else {
            // user has created a new streak
            
            // create BaseProfile object of current user
            let owner: [String] = [email, collection]
            
            // create streak with given inputs
            let newStreak = StreakInfo(owner: owner, name: streakName, description: streakDesc, reminderDays: daysOfWeekSelected, viewability: privacyType)
            
            // add user to StreakInfo's list of subscribers
            if cur_user_email != nil && cur_user_collection != nil {
                newStreak.subscribers.append(BaseProfile(profileType: cur_user_collection!, email: cur_user_email!))
            } else {
                print("Error: user not properly logged in. Streak created, but user not added to list of subscribers")
            }
            
            // add to proper collection of streaks
            var streakCollection = "private_streaks"
            if privacyType == .Friends {
                streakCollection = "friends_streaks"
            } else if privacyType == .Public {
                streakCollection = "public_streaks"
            }
            var ref: DocumentReference? = nil
            do {
                print("Attempting to add streak:", newStreak.name)
                ref = try db_firestore.collection(streakCollection).addDocument(from: newStreak)
                print("streak added with ID: \(ref!.documentID)")
            } catch let error {
                print("Error writing streak to Firestore: \(error)")
                return
            }
            
            // autosubscribe the user
            let subbedStreak = StreakSubscription(streakInfoId: ref!.documentID, reminderTime: reminderTimePicker.date, subscriptionStartDate: Date(), privacy: newStreak.viewability, reminderDays: newStreak.reminderDays, name: newStreak.name)
            
            // add streak to user profile
            curProfile.subscribedStreaks.append(subbedStreak)

            
            // update Firebase
            do {
                print("Attempting to add streak")
                try db_firestore.collection(collection).document(email).setData(from: curProfile)
                navigationController?.popViewController(animated: true)
            } catch let error {
                print("Error writing profile to Firestore: \(error)")
            }
        }
    }
    
    func persistEditToFirestore(streakInfo: StreakInfo, streakName: String, streakDesc: String, curProfile: Profile, idx: Int, streakInfoId: String, collection: String, email: String) {
        // add edits to StreakInfo
        streakInfo.name = streakName
        streakInfo.description = streakDesc
        streakInfo.reminderDays = daysOfWeekSelected
        
        // add edits to StreakSubscription
        curProfile.subscribedStreaks[idx].name = streakName
        curProfile.subscribedStreaks[idx].reminderDays = daysOfWeekSelected
        curProfile.subscribedStreaks[idx].reminderTime = reminderTimePicker.date
        
        // update streakinfo in firestore
        do {
            try db_firestore.collection("private_streaks").document(streakInfoId).setData(from: streakInfo)
        } catch let error {
            print("Error pushing streak edits to firestore: \(error)")
        }

        // update profile in firestore with streaksubscription changes
        do {
            try db_firestore.collection(collection).document(email).setData(from: curProfile)
        } catch let error {
            print("Error pushing streak edits to user profile: \(error)")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
