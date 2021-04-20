//
//  FriendsVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit

class FriendsVC: UIViewController {

    
    let searchFriendsSegueIdentifier = "SearchFriendsSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let curProfile = cur_user_profile else {
            return
        }
        
        for newFriend in curProfile.friendRequests {
            acceptFriendRequest(otherBaseProf: newFriend)
        }
    }
    
    func acceptFriendRequest(otherBaseProf: BaseProfile) {
        guard let myProfileType = cur_user_collection,
              let myEmail = cur_user_email,
              let myProfile = cur_user_profile,
              let indexOfRequest = myProfile.friendRequests.firstIndex(of: otherBaseProf) else {
            
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Get other profile from firebase
        db_firestore.collection(otherBaseProf.profileType).document(otherBaseProf.email).getDocument {
            (document, error) in
            if let document = document, document.exists {
                do {
                    let otherProfile = try document.data(as: Profile.self)!
                    
                    // Add yourself on the other profile's friend list
                    let myBaseProfile = BaseProfile(profileType: myProfileType, email: myEmail)
                    otherProfile.friends.append(myBaseProfile)
                    do {
                        try db_firestore.collection(otherBaseProf.profileType).document(otherBaseProf.email).setData(from: otherProfile)
                        
                        // Remove the other profile from your pending requests list
                        myProfile.friendRequests.remove(at: indexOfRequest)
                        
                        // Add other profile to your friends list
                        myProfile.friends.append(otherBaseProf)
                        
                        // update my profile in Firebase
                        do {
                            print("Attempting to update profile for", myEmail, "in", myProfileType)
                            try db_firestore.collection(myProfileType).document(myEmail).setData(from: myProfile)
                        } catch let error {
                            print("This is a critical error. We've added ourselves as someone's friend, but we can't update our own friends list because: Error writing profile to Firestore: \(error)")
                        }
                          
                    } catch let error {
                        print("Error accepting friend request: \(error)")
                        let alert = UIAlertController(
                            title: "Friend Request Error",
                            message: "We ran into issues accepting that friend request. Try again later",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    
                } catch {
                    print("Error deserializing profile - trying to get profile who sent me a friend request")
                }
            } else {
                print("Error fetching document")
            }
        }
        
    }

}
