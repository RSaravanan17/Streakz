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
    var filteredProfiles: [ProfileContainer] = []
    
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
            if let myProfileType = cur_user_collection, let myEmail = cur_user_email {
                db_firestore.collection(profile_type).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    
                    for document in documents {
                        let baseProf = BaseProfile(profileType: profile_type, email: document.documentID)
                        do {
                            let profile = try document.data(as: Profile.self)
                            self.profiles[baseProf] = profile
                        } catch {
                            print("Error deserializing profile in add friends screen")
                        }
                    }
                    
                    // Remove your profile - can't be friends with yourself
                    self.profiles.removeValue(forKey: BaseProfile(profileType: myProfileType, email: myEmail))
                    
                    
                    self.filteredProfiles = self.prepDataForTableView(dict: self.profiles)
                    self.usersTableView.reloadData()
                }
            }
        }
    }
    
    func prepDataForTableView(dict: [BaseProfile: Profile]) -> [ProfileContainer] {
        var result: [ProfileContainer] = []
        for (key, value) in dict {
            result.append(ProfileContainer(baseProfile: key, profile: value))
        }
        return result.sorted(by: { $0.profile.firstName < $1.profile.firstName })
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
        filteredProfiles = prepDataForTableView(dict: profiles)

        
        if !searchText.isEmpty {
            // filter all user profiles that contain the search text (case-insensitive) in the first or last name
            self.filteredProfiles = self.filteredProfiles.filter { (profileContainer: ProfileContainer) -> Bool in
                let containedInFirstName = profileContainer.profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profileContainer.profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                
                return containedInFirstName || containedInLastName
            }
        }
        
        self.usersTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        usersSearchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        usersSearchBar.setShowsCancelButton(false, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredProfiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.userCellIdentifier, for: indexPath as IndexPath) as! UserStreakCell
        let row = indexPath.row
        cell.styleView(profileContainer: filteredProfiles[row])
        return cell
    }

    
}



let SEND_REQUEST_TEXT = "Send Request"
let CANCEL_REQUEST_TEXT = "Cancel Request"
let ALREADY_FRIENDS_TEXT = "Already Friends!"
let THEY_WANT_YOU_TEXT = "Respond to request"

class UserStreakCell: UITableViewCell {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var mutualFriendCount: UILabel!
    @IBOutlet weak var sendFriendRequestButton: UIButton!
    
    var userProfileContainer: ProfileContainer?
    
    func styleView(profileContainer otherProfileContainer: ProfileContainer) {
        self.userProfileContainer = otherProfileContainer
        
        self.backgroundColor = UIColor(named: "Streakz_Background")
        self.layer.cornerRadius = 20
        self.accessoryType = .disclosureIndicator
        
        self.userName.text = otherProfileContainer.profile.firstName + " " + otherProfileContainer.profile.lastName
        self.mutualFriendCount.text = "Friends: \(otherProfileContainer.profile.friends.count)"
        
        guard let myProfile = cur_user_profile,
              let myProfileType = cur_user_collection,
              let myEmail = cur_user_email else {
            print("Problem styling UserStreakCell - cur_user data not set")
            return
        }
        
        self.sendFriendRequestButton.setTitleColor(UIColor.label, for: .normal)
        self.sendFriendRequestButton.layer.cornerRadius = 15
        
        if myProfile.friends.contains(otherProfileContainer.baseProfile) {
            // already friends
            self.sendFriendRequestButton.setTitle(ALREADY_FRIENDS_TEXT, for: .normal)
            self.sendFriendRequestButton.backgroundColor = UIColor.blue
            self.sendFriendRequestButton.isEnabled = false
        } else if otherProfileContainer.profile.friendRequests.contains(BaseProfile(profileType: myProfileType, email: myEmail)) {
            // friend request already sent
            self.sendFriendRequestButton.setTitle(CANCEL_REQUEST_TEXT, for: .normal)
            self.sendFriendRequestButton.backgroundColor = UIColor(named: "Streakz_DarkRed")
            self.sendFriendRequestButton.isEnabled = true
        } else if myProfile.friendRequests.contains(otherProfileContainer.baseProfile) {
            // they already sent me a request
            self.sendFriendRequestButton.setTitle(THEY_WANT_YOU_TEXT, for: .normal)
            self.sendFriendRequestButton.backgroundColor = UIColor(named: "Streakz_Yellow")
            self.sendFriendRequestButton.isEnabled = true
        } else {
            // I can send them a request
            self.sendFriendRequestButton.setTitle(SEND_REQUEST_TEXT, for: .normal)
            self.sendFriendRequestButton.backgroundColor = UIColor.green
            self.sendFriendRequestButton.isEnabled = true
        }
        
    }
    
    enum MyError: Error {
        case FoundNil;
    }
    
    
    
    
    @IBAction func sendFriendRequestButtonPressed(_ sender: Any) {
        
        
        guard let profileType = cur_user_collection, let email = cur_user_email, let container = userProfileContainer else {
            if let parent = self.parentViewController {
                let alert = UIAlertController(
                    title: "Invalid Session",
                    message: "We're having trouble finding out who you are, please try signing out and signing back in",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                parent.present(alert, animated: true, completion: nil)
            }
            return
        }
        
        if self.sendFriendRequestButton.title(for: .normal) == SEND_REQUEST_TEXT {
            // Send a friend request
            
            let requestSender = BaseProfile(profileType: profileType, email: email)
            let destination = container.profile
            let destCollection = container.baseProfile.profileType
            let destEmail = container.baseProfile.email
            destination.friendRequests.append(requestSender)
            do {
                print("Sending friend request")
                try db_firestore.collection(destCollection).document(destEmail).setData(from: destination)
            } catch let error {
                print("Error sending friend request: \(error)")
                if let parent = self.parentViewController {
                    let alert = UIAlertController(
                        title: "Friend Request Error",
                        message: "We ran into issues sending your friend request. Try again later",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    parent.present(alert, animated: true, completion: nil)
                }
            }
        } else if self.sendFriendRequestButton.title(for: .normal) == CANCEL_REQUEST_TEXT {
            // Remove pending friend request
            let requestSender = BaseProfile(profileType: profileType, email: email)
            let destination = container.profile
            let destCollection = container.baseProfile.profileType
            let destEmail = container.baseProfile.email
            
            do {
                if let index = destination.friendRequests.firstIndex(of: requestSender) {
                    destination.friendRequests.remove(at: index)
                } else {
                    throw MyError.FoundNil
                }
                
                print("Removing friend request")
                try db_firestore.collection(destCollection).document(destEmail).setData(from: destination)
            } catch let error {
                print("Error removing friend request: \(error)")
                if let parent = self.parentViewController {
                    let alert = UIAlertController(
                        title: "Friend Request Error",
                        message: "We ran into issues removing your friend request. Try again later",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    parent.present(alert, animated: true, completion: nil)
                }
            }
            
        } else if self.sendFriendRequestButton.title(for: .normal) == THEY_WANT_YOU_TEXT {
            // This user already sent us a request, let's segue to friends screen
            // TODO: segue to friends screen
        }
    }
}
