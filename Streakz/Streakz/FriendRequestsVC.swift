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

    var requestedFriends: [Profile] = []
    var filteredRequestedFriends: [Profile] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadRequests()
    }
    
    func loadRequests() {
        self.requestedFriends = []
        for requestedFriend in cur_user_profile?.friendRequests ?? [] {
            db_firestore.collection(requestedFriend.profileType).document(requestedFriend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    self.requestedFriends.append(fetchedProfile!)
                    self.filteredRequestedFriends = self.requestedFriends
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredRequestedFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.requestCellIdentifier, for: indexPath as IndexPath) as! RequestTableViewCell
        let row = indexPath.row
        let requestedFriend = self.filteredRequestedFriends[row]
        cell.styleViewWith(requestedFriend)
        
        // Set appropriate button function to handle friend request actions
        cell.onAcceptFriendRequest = {() in
            return self.onAcceptFriendRequest(newFriend: requestedFriend)
        }
        cell.onDeclineFriendRequest = {() in
            return self.onDeclineFriendRequest(newFriend: requestedFriend)
        }
        
        return cell
    }
    
    func onAcceptFriendRequest(newFriend: Profile) {
        print("Accepting Friend Request from \(newFriend.firstName)")
    }
    
    func onDeclineFriendRequest(newFriend: Profile) {
        print("Declining Friend Request from \(newFriend.firstName)")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.filteredRequestedFriends = self.requestedFriends.filter{(profile: Profile) -> Bool in
                let containedInFirstName = profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                return containedInFirstName || containedInLastName
            }
        } else {
            self.filteredRequestedFriends = self.requestedFriends
        }
        self.tableView.reloadData()
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
        
        let mutualFriendsCount = 0 // TODO: get number of mutual friends
        self.mutualFriendsLabel.textColor = UIColor(named: "Streakz_Grey")
        self.mutualFriendsLabel.text = "\(mutualFriendsCount) Mutual Friends"
        
        // Style accept and decline buttons
        self.acceptButton.layer.cornerRadius = 4
        self.declineButton.layer.cornerRadius = 4
        self.declineButton.layer.borderWidth = 1.0
        self.declineButton.layer.masksToBounds = false
        self.declineButton.layer.borderColor = UIColor(named: "Streakz_DarkRed")?.cgColor
    }
    
    @IBAction func onPressAccept(_ sender: Any) {
        self.onAcceptFriendRequest()
    }
    
    @IBAction func onPressDecline(_ sender: Any) {
        self.onDeclineFriendRequest()
    }
}
