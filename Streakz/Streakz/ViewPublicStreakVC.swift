//
//  ViewPublicStreakVC.swift
//  Streakz
//
//  Created by Michael on 4/7/21.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class ViewPublicStreakVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var streakNameLabel: UILabel!
    @IBOutlet weak var streakDescLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sundayView: UIView!
    @IBOutlet weak var mondayView: UIView!
    @IBOutlet weak var tuesdayView: UIView!
    @IBOutlet weak var wednesdayView: UIView!
    @IBOutlet weak var thursdayView: UIView!
    @IBOutlet weak var fridayView: UIView!
    @IBOutlet weak var saturdayView: UIView!
    
    var publicStreak: StreakInfo!
    
    var publicSubscribers: [Profile] = []
    
    let publicSubscriberCellIdentifier = "PublicSubscriberCell"
    
    let daysOfWeekTitles = ["Su", "M", "Tu", "W", "Th", "F", "Sa"]
    var daysOfWeekViews: [UIView?] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.streakNameLabel.text = publicStreak.name
        self.streakDescLabel.text = publicStreak.description
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.getPublicSubscribers()
        
        self.setFrequencyRow()
        
        self.checkIfAlreadySubbed()
    }

    func getPublicSubscribers() {
        let dispatchGroup = DispatchGroup()
        // Retreive list of profiles subbed to this streak
        for baseProfile in publicStreak.subscribers {
            let email = baseProfile.email
            dispatchGroup.enter()
            let type = baseProfile.profileType
            db_firestore.collection(type).document(email).getDocument { (document, error) in
                do {
                    if let document = document, document.exists {
                        let fullProfile = try document.data(as: Profile.self)
                        self.publicSubscribers.append(fullProfile!)
                    } else {
                        print("Document does not exist")
                    }
                } catch let error {
                    print("Error deserializing data while retreiving user from list of public streak subscribers", error)
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main, execute: {
            print("DEBUG: Fetched all public subscribers")
            self.tableView.reloadData()
        })

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.publicSubscribers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.publicSubscriberCellIdentifier, for: indexPath as IndexPath) as! PublicSubscriberCell
        let row = indexPath.row
        let profile = self.publicSubscribers[row]
        cell.styleViewWith(profile, publicStreak: self.publicStreak)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionName: String
        switch section {
            case 0:
                sectionName = "\(self.publicStreak.subscribers.count) Public Subscribers"
            default:
                sectionName = ""
        }
        return sectionName
    }
    
    // This function is needed to ensure the tableview's header resizes properly once the streak data is fetched
    // Code mostly taken from https://useyourloaf.com/blog/variable-height-table-view-header/
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let headerView = tableView.tableHeaderView else {
           return
        }
        
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        // Trigger a new layout only if the height has changed, otherwise it'd get stuck in a loop
        if headerView.frame.size.height != size.height {
           headerView.frame.size.height = size.height
           tableView.tableHeaderView = headerView
           tableView.layoutIfNeeded()
        }
    }
    
    func subscribeToStreak(reminderTime: Date) {
        // TODO: Guard against resubbing to this streak
        
        // add user to StreakInfo's list of subscribers
        if cur_user_email != nil && cur_user_collection != nil {
            publicStreak.subscribers.append(BaseProfile(profileType: cur_user_collection!, email: cur_user_email!))
            for sub in publicStreak.subscribers {
                print(sub.email)
            }
        } else {
            print("Error: user not properly logged in. Streak created, but user not added to list of subscribers")
        }
        
        if (publicStreak.viewability == .Friends) {
            db_firestore.collection("friends_streaks").whereField("name", isEqualTo: publicStreak.name).getDocuments() {
                (querySnapshot, err) in
                if let err = err {
                    print("Error fetching documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // autosubscribe the user
                        let subbedStreak = StreakSubscription(streakInfoId: document.documentID, reminderTime: reminderTime, subscriptionStartDate: Date(), privacy: self.publicStreak.viewability, reminderDays: self.publicStreak.reminderDays, name: self.publicStreak.name)
                        
                        // add streak to user profile
                        cur_user_profile!.subscribedStreaks.append(subbedStreak)
                        
                        // update friends streak in Firebase
                        do {
                            try db_firestore.collection("friends_streaks").document(document.documentID).setData(from: self.publicStreak)
                        } catch let error {
                            print("Error writing profile to Firestore: \(error)")
                        }
                    }
                    
                    // update user profile in Firebase
                    do {
                        print("Attempting to add streak for", cur_user_email!, "in", cur_user_collection!)
                        try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: cur_user_profile)
                        self.navigationController?.popViewController(animated: true)
                    } catch let error {
                        print("Error writing profile to Firestore: \(error)")
                    }
                }
            }
        } else if(publicStreak.viewability == .Public) {
            db_firestore.collection("public_streaks").whereField("name", isEqualTo: publicStreak.name).getDocuments() {
                (querySnapshot, err) in
                if let err = err {
                    print("Error fetching documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        // autosubscribe the user
                        let subbedStreak = StreakSubscription(streakInfoId: document.documentID, reminderTime: reminderTime, subscriptionStartDate: Date(), privacy: self.publicStreak.viewability, reminderDays: self.publicStreak.reminderDays, name: self.publicStreak.name)
                        
                        // add streak to user profile
                        cur_user_profile!.subscribedStreaks.append(subbedStreak)
                        
                        // update public streak in Firebase
                        do {
                            try db_firestore.collection("public_streaks").document(document.documentID).setData(from: self.publicStreak)
                        } catch let error {
                            print("Error writing profile to Firestore: \(error)")
                        }
                    }
                    
                    // update user profile in Firebase
                    do {
                        print("Attempting to add streak for", cur_user_email!, "in", cur_user_collection!)
                        try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: cur_user_profile)
                        self.navigationController?.popViewController(animated: true)
                    } catch let error {
                        print("Error writing profile to Firestore: \(error)")
                    }
                }
            }
        }
    }
    
    @IBAction func onSubscribeButtonPressed(_ sender: Any) {
        // set bounds for picker within alert
        let vcWidth = 250
        let vcHeight = 100
        let pickerWidth = 96
        let pickerHeight = 48
        // create view to store picker
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: vcWidth, height: vcHeight)
        // center picker within the alert view
        let pickerX = (vcWidth / 2) - (pickerWidth / 2)
        let pickerY = (vcHeight / 2) - (pickerHeight / 2)
        let pickerView = UIDatePicker(frame: CGRect(x: pickerX, y: pickerY, width: pickerWidth, height: pickerHeight))
        pickerView.datePickerMode = .time
        pickerView.minuteInterval = 15
        // add picker to view
        vc.view.addSubview(pickerView)
        // create alert and embed view in it
        let streakTimeAlert = UIAlertController(title: "Choose a reminder time",
                                                message: "When would you like to be reminded to complete this streak?",
                                                preferredStyle: UIAlertController.Style.alert)
        streakTimeAlert.view.tintColor = UIColor(named: "Streakz_DarkRed")
        streakTimeAlert.setValue(vc, forKey: "contentViewController")
        streakTimeAlert.addAction(UIAlertAction(title: "Subscribe",
                                                style: .default,
                                                handler: { _ in
                                                    print("User is subscribing to public streak")
                                                    self.subscribeToStreak(reminderTime: pickerView.date)
                                                }))
        streakTimeAlert.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: { _ in
                                                    print("Public streak subscribe cancelled")
                                                }))
        self.present(streakTimeAlert, animated: true)
    }
    
    func checkIfAlreadySubbed() {
        let subbedStreakNames = cur_user_profile!.subscribedStreaks.map({ (subbedStreak: StreakSubscription) -> String in return subbedStreak.name })
        
        if subbedStreakNames.contains(self.publicStreak.name) {
            self.subscribeButton.backgroundColor = UIColor(named: "Streakz_Grey")
            self.subscribeButton.setTitle("Already Subscribed", for: .disabled)
            self.subscribeButton.isEnabled = false
        }
    }
    
    func setFrequencyRow() {
        self.daysOfWeekViews = [
            self.sundayView,
            self.mondayView,
            self.tuesdayView,
            self.wednesdayView,
            self.thursdayView,
            self.fridayView,
            self.saturdayView
        ]
        // Add buttons to each day of the week view
        for (i, view) in daysOfWeekViews.enumerated() {
            let isSelected = self.publicStreak.reminderDays[i]
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            button.backgroundColor = isSelected ? UIColor(named: "Streakz_DarkRed") : UIColor.gray
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            button.setTitle(daysOfWeekTitles[i], for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.isEnabled = false
            view?.addSubview(button)
        }
    }
}

class PublicSubscriberCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var streakCountLabel: UILabel!
    
    func styleViewWith(_ profile: Profile, publicStreak: StreakInfo) {
        // Style image view
        self.profileImageView.layer.borderWidth = 1.0
        self.profileImageView.layer.masksToBounds = false
        self.profileImageView.layer.borderColor = UIColor.white.cgColor
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        
        // Set fields
        let imageURL: String = profile.profilePicture
        if imageURL == "" {
            self.profileImageView.image = UIImage(named: "ProfileImageBlank")
        } else {
            self.profileImageView.load(url: URL(string: imageURL)!)
        }
        self.nameLabel.text = "\(profile.firstName) \(profile.lastName)"
        
        let streaks = profile.subscribedStreaks.filter({(streak: StreakSubscription) -> Bool in return streak.name == publicStreak.name})
        var streakCount = 0
        if streaks.count > 0 {
            streakCount = streaks[0].streakNumber
        }
        self.streakCountLabel.textColor = UIColor(named: "Streakz_Grey")
        self.streakCountLabel.text = "Streak: \(streakCount)"
    }
}
