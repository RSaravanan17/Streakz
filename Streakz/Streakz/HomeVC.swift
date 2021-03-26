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
                tableView.deselectRow(at: streakSubIndexPath, animated: false)
        } else if segue.identifier == addStreakSegueIdentifier,
                  let nextVC = segue.destination as? AddStreakVC {
            nextVC.curUserProfile = userProfile
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
        backgroundColor = UIColor(named: "Streakz_Background")
        layer.cornerRadius = 20
    }
}
