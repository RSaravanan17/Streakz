//
//  FriendRequestsVC.swift
//  Streakz
//
//  Created by Michael on 4/22/21.
//

import UIKit

class FriendRequestsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let requestCellIdentifier = "RequestCellIdentifier"

    var requestedFriends: [ProfileContainer] = []
    var filteredRequestedFriends: [ProfileContainer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadRequests()
        let pluralString: String = (cur_user_profile?.friendRequests.count ?? 0) == 1 ? "" : "s"
        self.searchBar.prompt = "\(cur_user_profile?.friendRequests.count ?? 0) Friend Request\(pluralString)"
    }
    
    func loadRequests() {
        self.requestedFriends = []
        self.filteredRequestedFriends = self.requestedFriends
        for requestedFriend in cur_user_profile?.friendRequests ?? [] {
            db_firestore.collection(requestedFriend.profileType).document(requestedFriend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    self.requestedFriends.append(ProfileContainer(baseProfile: requestedFriend, profile: fetchedProfile!))
                    self.filteredRequestedFriends = self.requestedFriends
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
            }
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredRequestedFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.requestCellIdentifier, for: indexPath as IndexPath) as! RequestTableViewCell
        let row = indexPath.row
        let requestedFriend = self.filteredRequestedFriends[row]
        cell.mutualFriendsCount = self.getMutualFriends(cur_user_profile!, requestedFriend.profile)
        cell.styleViewWith(requestedFriend.profile)
        
        // Set appropriate button function to handle friend request actions
        cell.onAcceptFriendRequest = {() in
            return self.onAcceptFriendRequest(acceptedFriend: requestedFriend)
        }
        cell.onDeclineFriendRequest = {() in
            return self.onDeclineFriendRequest(declinedFriend: requestedFriend)
        }
        
        return cell
    }
    
    func onAcceptFriendRequest(acceptedFriend: ProfileContainer) {
        guard let profileType = cur_user_collection, let email = cur_user_email else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        print("Accepting Friend Request from \(acceptedFriend.profile.firstName)")
        do {
            // Add friend to this user's list of friends
            let requestSender = BaseProfile(profileType: profileType, email: email)
            let updateUserProfile: Profile = cur_user_profile!
            updateUserProfile.friends.append(acceptedFriend.baseProfile)
            // Remove friend request from this users list of friend requests
            if let index = updateUserProfile.friendRequests.firstIndex(of: acceptedFriend.baseProfile) {
                updateUserProfile.friendRequests.remove(at: index)
            } else {
                throw MyError.FoundNil
            }
            try db_firestore.collection(profileType).document(email).setData(from: updateUserProfile)
            
            // Add this user to the other users list of friends
            let destination = acceptedFriend.profile
            let destCollection = acceptedFriend.baseProfile.profileType
            let destEmail = acceptedFriend.baseProfile.email
            destination.friends.append(requestSender)
            try db_firestore.collection(destCollection).document(destEmail).setData(from: destination)
            
            // Refresh list of friend requests
            self.loadRequests()
        } catch let error {
            print("Error accepting friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues accepting the friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func onDeclineFriendRequest(declinedFriend: ProfileContainer) {
        guard let profileType = cur_user_collection, let email = cur_user_email else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        print("Declining Friend Request from \(declinedFriend.profile.firstName)")
        do {
            let updateUserProfile: Profile = cur_user_profile!
            // Remove friend request from this users list of friend requests
            if let index = updateUserProfile.friendRequests.firstIndex(of: declinedFriend.baseProfile) {
                updateUserProfile.friendRequests.remove(at: index)
            } else {
                throw MyError.FoundNil
            }
            try db_firestore.collection(profileType).document(email).setData(from: updateUserProfile)
                        
            // Refresh list of friend requests
            self.loadRequests()
        } catch let error {
            print("Error declining friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues declining the friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.filteredRequestedFriends = self.requestedFriends.filter{(profileContainer: ProfileContainer) -> Bool in
                let profile = profileContainer.profile
                let containedInFirstName = profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                return containedInFirstName || containedInLastName
            }
        } else {
            self.filteredRequestedFriends = self.requestedFriends
        }
        self.tableView.reloadData()
    }
    
    func getMutualFriends(_ profile1: Profile, _ profile2: Profile) -> Int {
        let friendsSet1: Set<BaseProfile> = Set(profile1.friends)
        let friendsSet2: Set<BaseProfile> = Set(profile2.friends)
        return (friendsSet1.intersection(friendsSet2)).count
    }
    
    enum MyError: Error {
        case FoundNil;
    }
}

class RequestTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mutualFriendsLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
        
    var onAcceptFriendRequest: (() -> Void)!
    var onDeclineFriendRequest: (() -> Void)!
    var mutualFriendsCount: Int = 0
    
    func styleViewWith(_ profile: Profile) {
        // Style image view
        self.profileImage.layer.borderWidth = 1.0
        self.profileImage.layer.masksToBounds = false
        self.profileImage.layer.borderColor = UIColor(named: "Streakz_Grey")?.cgColor
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        self.profileImage.clipsToBounds = true
        
        // Set fields
        let imageURL: String = profile.profilePicture
        if imageURL == "" {
            self.profileImage.image = UIImage(named: "ProfileImageBlank")
        } else {
            self.profileImage.load(url: URL(string: imageURL)!)
        }
        self.nameLabel.text = "\(profile.firstName) \(profile.lastName)"
        
        self.mutualFriendsLabel.textColor = UIColor(named: "Streakz_Grey")
        self.mutualFriendsLabel.text = "\(self.mutualFriendsCount) Mutual Friends"
        
        // Style accept and decline buttons
        self.acceptButton.layer.cornerRadius = 4
        self.declineButton.layer.cornerRadius = 4
        self.declineButton.layer.borderWidth = 1.0
        self.declineButton.layer.masksToBounds = false
        self.declineButton.layer.borderColor = UIColor(named: "Streakz_DarkRed")?.cgColor
    }
    
    @IBAction func onPressAccept(_ sender: UIButton) {
        sender.alpha = 0.5
        
        /*
        Code should execute after 0.2 second delay.
        You can change delay by editing 0.2.
        */
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          // Bring's sender's opacity back up to fully opaque
          sender.alpha = 1.0
        }
        
        self.onAcceptFriendRequest()
    }
    
    @IBAction func onPressDecline(_ sender: UIButton) {
        sender.alpha = 0.5
        
        /*
        Code should execute after 0.2 second delay.
        You can change delay by editing 0.2.
        */
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          // Bring's sender's opacity back up to fully opaque
          sender.alpha = 1.0
        }
        
        self.onDeclineFriendRequest()
    }
}
