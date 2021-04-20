//
//  SearchFriendsViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 4/9/21.
//

import UIKit

class ProfileContainer {
    let baseProfile: BaseProfile
    let profile: Profile
    
    init(baseProfile: BaseProfile, profile: Profile) {
        self.baseProfile = baseProfile
        self.profile = profile
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}

class SearchFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var usersSearchBar: UISearchBar!
    @IBOutlet weak var usersTableView: UITableView!
    
    let userCellIdentifier = "UserCellIdentifier"
    
    var profiles: [BaseProfile: Profile] = [:]
    var filteredProfiles: [BaseProfile: Profile] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.usersSearchBar.delegate = self
        self.usersTableView.delegate = self
        self.usersTableView.dataSource = self

        loadUsers()
    }
    
    func loadUsers() {
        // fetch profile for current list of users
        let profile_types = ["profiles_email", "profiles_google", "profiles_facebook"]
        
        for profile_type in profile_types {
            if let _ = cur_user_collection, let _ = cur_user_email {
                db_firestore.collection(profile_type).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    
                    // clear profiles to rid of any stale data
//                    self.profiles = []
//                    self.filteredProfiles = []
                    
                    // first three lists, hashmap, or just check list
                    
                    for document in documents {
                        let baseProf = BaseProfile(profileType: profile_type, email: document.documentID)
                        do {
                            let profile = try document.data(as: Profile.self)
                            let profileContainer = ProfileContainer(baseProfile: baseProf, profile: profile!)
                            self.profiles.append(profileContainer)
                        } catch {
                            print("Error deserializing profile in add friends screen")
                        }
                    }
                    
                    self.filteredProfiles = self.profiles
                    
                    self.usersTableView.reloadData()
                }
            }
        }
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            // filter all user profiles that contain the search text (case-insensitive) in the first or last name
            self.filteredProfiles = self.profiles.filter { (profileContainer: ProfileContainer) -> Bool in
                let containedInFirstName = profileContainer.profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profileContainer.profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                
                return containedInFirstName || containedInLastName
            }
        } else {
            // when search text is empty, display all users
            self.filteredProfiles = self.profiles
        }
        
        self.usersTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredProfiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.userCellIdentifier, for: indexPath as IndexPath) as! UserStreakCell
        let row = indexPath.row
        let array = filteredProfiles.keys.sorted(by: { $0.email < $1.email })
        let baseProfile = array[row]
        let curProfileContainer = ProfileContainer(baseProfile: baseProfile, profile: self.filteredProfiles[baseProfile]!)
        cell.styleView(profileContainer: curProfileContainer)
        return cell
    }

}

class UserStreakCell: UITableViewCell {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var mutualFriendCount: UILabel!
    @IBOutlet weak var sendFriendRequestButton: UIButton!
    
    var userProfileContainer: ProfileContainer?
    
    func styleView(profileContainer: ProfileContainer) {
        self.userProfileContainer = profileContainer
        
        self.backgroundColor = UIColor(named: "Streakz_Background")
        self.layer.cornerRadius = 20
        self.accessoryType = .disclosureIndicator
        
        self.userName.text = profileContainer.profile.firstName + " " + profileContainer.profile.lastName
        self.mutualFriendCount.text = "Friends: \(profileContainer.profile.friends.count)"
        
        self.sendFriendRequestButton.setTitle("Send Friend Request", for: .normal)
        self.sendFriendRequestButton.backgroundColor = UIColor.green
        self.sendFriendRequestButton.setTitleColor(UIColor.white, for: .normal)
        self.sendFriendRequestButton.layer.cornerRadius = 15
    }
    
    @IBAction func sendFriendRequestButtonPressed(_ sender: Any) {
//        if let profileType = cur_user_collection, let email = cur_user_email, let container = userProfileContainer {
//            let requestSender = BaseProfile(profileType: profileType, email: email)
//            let destination = container.profile
//            let destCollection = container.baseProfile.profileType
//            let destEmail = container.baseProfile.email
//            destination.friendRequests.append(requestSender)
//            do {
//                print("Sending friend request")
//                try db_firestore.collection(destCollection).document(destEmail).setData(from: destination)
//            } catch let error {
//                print("Error sending friend request: \(error)")
//                if let parent = self.parentViewController {
//                    let alert = UIAlertController(
//                        title: "Friend Request Error",
//                        message: "We ran into issues sending your friend request. Try again later",
//                        preferredStyle: .alert
//                    )
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                    parent.present(alert, animated: true, completion: nil)
//                }
//            }
//        } else {
//            if let parent = self.parentViewController {
//                let alert = UIAlertController(
//                    title: "Invalid Session",
//                    message: "We're having trouble finding out who you are, please try signing out and signing back in",
//                    preferredStyle: .alert
//                )
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                parent.present(alert, animated: true, completion: nil)
//            }
//        }
    }
}
