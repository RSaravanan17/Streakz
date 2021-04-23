//
//  FriendsListVC.swift
//  Streakz
//
//  Created by Michael on 4/22/21.
//

import UIKit

class FriendsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let friendCellIdentifier = "FriendCellIdentifier"
    
    var friends: [Profile] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.loadFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadFriends()
    }
    
    func loadFriends() {
        for friend in cur_user_profile?.friends ?? [] {
            db_firestore.collection(friend.profileType).document(friend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    self.friends.append(fetchedProfile!)
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
            }
            self.tableView.reloadData()
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.friendCellIdentifier, for: indexPath as IndexPath) as! FriendTableViewCell
        let row = indexPath.row
        let friend = self.friends[row]
        print(friend.firstName)
        print(friend.lastName)
        cell.styleViewWith(friend)
        return cell
    }
}

class FriendTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var streakLabel: UILabel!
    
    func styleViewWith(_ profile: Profile) {
        // Style image view
        self.profileImage.layer.borderWidth = 1.0
        self.profileImage.layer.masksToBounds = false
        self.profileImage.layer.borderColor = UIColor.white.cgColor
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
        
        let activeStreakCount = profile.subscribedStreaks
        self.streakLabel.textColor = UIColor(named: "Streakz_Grey")
        self.streakLabel.text = "\(activeStreakCount) Active Streakz"
    }
}
