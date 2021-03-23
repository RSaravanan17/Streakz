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
    
    var subscribedStreaks: [StreakSubscription] = [StreakSubscription(streakInfo: StreakInfo(owner: "Test User", name: "Test Streak", description: "Do a test streak"), reminderTime: Date(), subscriptionStartDate: Date(), privacy: StreakSubscription.PrivacyType.Private)]
    
    var homeStreakCellIdentifier = "HomeStreakCellIdentifier"
    var viewStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // test put profile code
//        let profile = Profile(firstName: "TestFirst", lastName: "TestLast")
//        let streakInfo = StreakInfo(owner: "TestPerson", name: "PUSH UPS!", description: "Make gains")
//        let streakSub = StreakSubscription(streakInfo: streakInfo, reminderTime: Date(), subscriptionStartDate: Date(), privacy: .Private)
//        profile.friends = [Profile(firstName: "Test", lastName: "Friend")]
//        profile.subscribedStreaks = [streakSub]
//        profile.streakPosts = [StreakPost()]
//        
//        do {
//            try db_firestore.collection("profiles_email").document("TestDocument").setData(from: profile)
//        } catch let error {
//            print("Error writing profile to Firestore: \(error)")
//        }
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscribedStreaks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: homeStreakCellIdentifier, for: indexPath as IndexPath)
        let row = indexPath.row
        let streakSub = subscribedStreaks[row]
        cell.textLabel?.text = streakSub.streakInfo.name
        return cell
        
    }
    
    // This is needed to unselect after a user taps a cell
    // Otherwise when we return from ViewStreakVC, the cell will be highlighted
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Change the selected background view of the cell.
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewStreakSegueIdentifier,
           let nextVC = segue.destination as? ViewStreakVC,
            let streakSubIndex = tableView.indexPathForSelectedRow?.row
        {
                nextVC.streakSub = subscribedStreaks[streakSubIndex]
                tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: false)

        }
        
    }

}
