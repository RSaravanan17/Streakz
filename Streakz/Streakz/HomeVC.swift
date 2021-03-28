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

class HomeVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userProfile: Profile?
    var subscribedStreaks: [StreakSubscription] = [StreakSubscription(streakInfo: StreakInfo(owner: "Test User", name: "Debug Streak", description: "a test streak", reminderDays: [true, false, false, false, false, false, false]), reminderTime: Date(), subscriptionStartDate: Date(), privacy: StreakSubscription.PrivacyType.Private), StreakSubscription(streakInfo: StreakInfo(owner: "Another Test User", name: "If you see this something went wrong getting your profile's streaks", description: "another test streak", reminderDays: [false, false, false, true, false, false, false]), reminderTime: Date(), subscriptionStartDate: Date(), privacy: StreakSubscription.PrivacyType.Private)]
    
    var streakCellIdentifier = "StreakCellIdentifier"
    var viewStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    var addStreakSegueIdentifier = "AddStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // fetch profile for current list of streaks from firebase
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscribedStreaks.count
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
         return "Unsubscribe"
    }
    
    // allows rows to be deleted from the table
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let owner = cur_user_email,
               let collection = cur_user_collection,
               let curProfile = self.userProfile {
                self.subscribedStreaks.remove(at: indexPath.row)
                self.userProfile?.subscribedStreaks = subscribedStreaks
                
                // deletes the row in the tableView
                // can add animation if desired but need to fix TableCell corner rounding
                //tableView.deleteRows(at: [indexPath], with: .fade)
                
                // update firebase
                do {
                    print("Attempting to delete Streak \(indexPath.row) for", cur_user_email!, "in", cur_user_collection!)
                    try db_firestore.collection(collection).document(owner).setData(from: curProfile)
                    navigationController?.popViewController(animated: true)
                } catch let error {
                    print("Error writing profile to Firestore: \(error)")
                }
            } else {
                print("Could not delete Streak \(indexPath.row)")
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: streakCellIdentifier, for: indexPath as IndexPath) as! StreakCell
        let row = indexPath.row
        let streakSub = subscribedStreaks[row]
        cell.styleView(streak: streakSub)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewStreakSegueIdentifier,
           let nextVC = segue.destination as? ViewStreakVC,
           let streakSubIndexPath = tableView.indexPathForSelectedRow {
            
            nextVC.streakSub = subscribedStreaks[streakSubIndexPath.row]
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
            if streakSub.nextDeadline() < currentDate || currentDate < streakSub.lastStreakUpdate {
                // The left hand side of this OR checks if the user has missed their deadline
                
                // The right hand side of the OR checks if this streak was updated at some point in the future.
                // If streakSub.lastStreakUpdate is in the future, behavior will not be as expected
                // Realistically, this should never happen, but it happens quite often for us when debugging b/c we have to
                // change our system time in order to test out the app without actually having to wait a week for the right Date
                
                // In either case, we need to reset the streak
                print("Streak Expired:", streakSub.streakInfo.name)
                streakSub.resetStreak()
                needToUpdateDB = true
            }
        }

        if needToUpdateDB,
           let curProfile = userProfile {
            // update firebase
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
        title?.text = streak.streakInfo.name
        streakNumber?.text = String(streak.streakNumber)
        view.layer.cornerRadius = 20
        
        if streak.canBeCompletedToday() {
            view.backgroundColor = UIColor(named: "Streakz_Background")
        } else {
            view.backgroundColor = UIColor(named: "Streakz_Grey")
        }
    }
}
