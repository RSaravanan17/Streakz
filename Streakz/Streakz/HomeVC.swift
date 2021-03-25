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
    
    var subscribedStreaks: [StreakSubscription] = [StreakSubscription(streakInfo: StreakInfo(owner: "Test User", name: "Test Streak", description: "Do a test streak", reminderDays: [false, false, false, false, false, false, false]), reminderTime: Date(), subscriptionStartDate: Date(), privacy: StreakSubscription.PrivacyType.Private), StreakSubscription(streakInfo: StreakInfo(owner: "Another Test User", name: "Another Test Streak", description: "Do another test streak", reminderDays: [false, false, false, false, false, false, false]), reminderTime: Date(), subscriptionStartDate: Date(), privacy: StreakSubscription.PrivacyType.Private)]
    
    var streakCellIdentifier = "StreakCellIdentifier"
    var viewStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // test put profile code
//        let profile = Profile(firstName: "TestFirst", lastName: "TestLast")
//        let streakInfo = StreakInfo(owner: "TestPerson", name: "PUSH UPS!", description: "Make gains", reminderDays: [false, false, false, false, false, false, false])
//        let streakSub = StreakSubscription(streakInfo: streakInfo, reminderTime: Date(), subscriptionStartDate: Date(), privacy: .Private)
//        let friend = Profile(firstName: "Test", lastName: "Friend")
//        friend.subscribedStreaks = [streakSub]
//        profile.friends = [friend]
//        profile.subscribedStreaks = [streakSub]
//        profile.streakPosts = [StreakPost()]
//        do {
//            try db_firestore.collection("profiles_email").document("TestDocument").setData(from: profile)
//        } catch let error {
//            print("Error writing profile to Firestore: \(error)")
//        }
        
//        // test update code
//        let newProfile = Profile(firstName: "New", lastName: "Friend")
//        newProfile.subscribedStreaks = [streakSub]
//        let json = try! JSONEncoder().encode(newProfile)
//        let betterThing =  try? JSONSerialization.jsonObject(with: json, options: .allowFragments)
//        db_firestore.collection("profiles_email").document("TestDocument").updateData([
//            "friends": FieldValue.arrayUnion([betterThing!])
//        ])
        
        // test fetch profile code
//        db_firestore.collection("profiles_email").document("TestDocument").getDocument {
//            (document, error) in
//            let result = Result {
//                try document?.data(as: Profile.self)
//            }
//            switch result {
//            case .success(let fetchedProfile):
//                if let fetchedProfile = fetchedProfile {
//                    print("Received profile successfully")
//                    print(fetchedProfile.firstName, fetchedProfile.lastName, fetchedProfile.friends[0].firstName)
//                } else {
//                    print("Document doesn't exist")
//                }
//            case .failure(let error):
//                print("Error decoding document into profile: \(error)")
//            }
//        }
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
            let streakSubIndexPath = tableView.indexPathForSelectedRow
        {
            nextVC.streakSub = subscribedStreaks[streakSubIndexPath.row]
                tableView.deselectRow(at: streakSubIndexPath, animated: false)
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
