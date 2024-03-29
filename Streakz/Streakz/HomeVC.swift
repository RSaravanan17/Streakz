//
//  HomeVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import Firebase
import FirebaseFirestoreSwift

class HomeVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var homeSearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var userProfile: Profile?
    var subscribedStreaks: [StreakSubscription] = []
    var sections: [[StreakSubscription]] = [[]]
    let sectionTypes = [true, false] // true is an incomplete streak (it CAN be completed today) false is a complete streak (can't be completed today)
    let sectionTitles = ["Incomplete", "Complete"]
    var streakCellIdentifier = "StreakCellIdentifier"
    var viewStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    var addStreakSegueIdentifier = "AddStreakSegueIdentifier"
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.homeSearchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // fetch profile for current list of streaks from Firebase
        if let collection = cur_user_collection, let user = cur_user_email {
            db_firestore.collection(collection).document(user)
                .addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard document.data() != nil else {
                        print("Document data was empty.")
                        return
                    }
                    do {
                        let userProfile = try document.data(as: Profile.self)
                        self.userProfile = userProfile
                        self.subscribedStreaks = userProfile!.subscribedStreaks
                        self.verifyStreaks(streakSubs: self.subscribedStreaks)
                        
                        // split table view into sections (complete and incomplete streaks sorted by name)
                        self.sections = self.sectionTypes.map { type in
                            return self.subscribedStreaks
                                .filter { $0.canBeCompletedToday() == type }
                                .sorted { $0.name < $1.name }
                        }
                        
                        self.tableView.reloadData()
                    } catch let error {
                        print("Error deserializing data", error)
                    }
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.homeSearchBar.setShowsCancelButton(true, animated: true)
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            // filter all streakz in both sections that contain the search text (case-insensitive) in the name
            self.sections = self.sectionTypes.map { type in
                return self.subscribedStreaks
                    .filter { $0.canBeCompletedToday() == type }
                    .sorted { $0.name < $1.name }
                    .filter { (streakSub: StreakSubscription) -> Bool in
                        let containedInStreakName = streakSub.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                        
                        return containedInStreakName
                    }
            }
        } else {
            // when search text is empty, display all streakz
            // split table view into sections (complete and incomplete streaks sorted by name)
            self.sections = self.sectionTypes.map { type in
                return self.subscribedStreaks
                    .filter { $0.canBeCompletedToday() == type }
                    .sorted { $0.name < $1.name }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        self.homeSearchBar.setShowsCancelButton(false, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if sections.count == 2 && sections[0].count == 0 && sections[1].count == 0 {
            tableView.setEmptyMessage("No streaks :/\nAdd a new streak to start your collection!")
        } else {
            tableView.restore()
        }
        return sections.count
    }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].count > 0 ? sectionTitles[section] : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: streakCellIdentifier, for: indexPath as IndexPath) as! StreakCell
        let streakSub = sections[indexPath.section][indexPath.row]
        cell.styleView(streak: streakSub)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
         return "Unsubscribe"
    }
    
    // allows rows to be deleted from the table
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let email = cur_user_email,
               let collection = cur_user_collection,
               let curProfile = self.userProfile {
                
                let streakId = self.sections[indexPath.section][indexPath.row].streakInfoId
                let streakCollectionType = self.sections[indexPath.section][indexPath.row].privacy
                
                var streakCollection: String?
                switch streakCollectionType {
                    case .Private:
                        streakCollection = "private_streaks"
                    case .Friends:
                        streakCollection = "friends_streaks"
                    case .Public:
                        streakCollection = "public_streaks"
                }
                
                
                // remove streak from local list and user profile subscription sectioned list
                self.sections[indexPath.section].remove(at: indexPath.row)
                self.userProfile?.subscribedStreaks = []
                for section in self.sections {
                    self.userProfile?.subscribedStreaks += section
                }
                
                
                // update Firebase
                do {
                    print("Attempting to delete Streak \(indexPath.row) for", email, "in", collection)
                    // update the user's profile in Firebase
                    try db_firestore.collection(collection).document(email).setData(from: curProfile)
                    
                    // retrieve StreakInfo object
                    var cur_public_streak: StreakInfo?
                    db_firestore.collection(streakCollection!).document(streakId).getDocument { (document, error) in
                        do {
                            if let document = document, document.exists {
                                // deserialize retrieved object into StreakInfo object
                                cur_public_streak = try document.data(as: StreakInfo.self)
                                
                                // remove current user from the streak's subscriber list
                                cur_public_streak?.subscribers.removeAll{$0.email == email && $0.profileType == collection}
                                
                                // update the StreakInfo object in Firebase
                                try db_firestore.collection(streakCollection!).document(streakId).setData(from: cur_public_streak!)
                            } else {
                                print("Document does not exist")
                            }
                        } catch let error {
                            print("Error deserializing data while deleting user from public streak", error)
                        }
                    }
                    
                    navigationController?.popViewController(animated: true)
                } catch let error {
                    print("Error writing profile to Firestore: \(error)")
                }
            } else {
                print("Could not delete Streak \(indexPath.row)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewStreakSegueIdentifier,
           let nextVC = segue.destination as? ViewStreakVC,
           let streakSubIndexPath = tableView.indexPathForSelectedRow {
            
            nextVC.streakSub = sections[streakSubIndexPath.section][streakSubIndexPath.row]
            nextVC.curUserProfile = userProfile
            tableView.deselectRow(at: streakSubIndexPath, animated: false)
            
        } else if segue.identifier == addStreakSegueIdentifier,
                  let nextVC = segue.destination as? AddStreakVC {
            
            nextVC.curUserProfile = userProfile
        }
    }
    
    func verifyStreaks(streakSubs: [StreakSubscription]) {
        let currentDate = Date()
        var needToUpdateDB = false
        for streakSub in streakSubs {
            if streakSub.streakExpired() || currentDate < streakSub.lastStreakUpdate {
                // The left hand side of this OR checks if the user has missed their deadline
                
                // The right hand side of the OR checks if this streak was updated at some point in the future.
                // If streakSub.lastStreakUpdate is in the future, behavior will not be as expected
                
                // Realistically, this should never happen, but it happens quite often for us when debugging b/c we have to
                // change our system time in order to test out the app without actually having to wait a week for the right Date
                
                // In practice, this will also help prevent users who attempt to cheese the system by changing their device time.
                // A user could inflate their streakNumber by changing their device time and completing streaks ahead of time
                // However, this will reset their streak back to zero once they reset their device to actual time
                
                // In any case, we need to reset the streak back to zero
                print("Streak Expired:", streakSub.name)
                streakSub.resetStreak()
                needToUpdateDB = true
            }
        }

        if needToUpdateDB,
           let curProfile = userProfile {
            // update Firebase
            do {
                print("Some streaks have expired, updating database")
                try db_firestore.collection(cur_user_collection!).document(cur_user_email!).setData(from: curProfile)
            } catch let error {
                print("Error writing profile to Firestore: \(error)")
            }
        }
    }
}

class StreakCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var streakNumber: UILabel!
    
    func styleView(streak: StreakSubscription) {
        title?.text = streak.name
        streakNumber?.text = String(streak.streakNumber)
        view.layer.cornerRadius = 20
        
        if streak.canBeCompletedToday() {
            view.backgroundColor = UIColor(named: "Streakz_Background")
        } else {
            view.backgroundColor = UIColor(named: "Streakz_Grey")
        }
    }
}
