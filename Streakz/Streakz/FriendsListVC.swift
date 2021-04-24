//
//  FriendsListVC.swift
//  Streakz
//
//  Created by Michael on 4/22/21.
//

import UIKit

class FriendsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let friendCellIdentifier = "FriendCellIdentifier"
    
    var friends: [Profile] = []
    var filteredFriends: [Profile] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Fetch friends list and populate table
        self.loadFriends()
        let pluralString: String = (cur_user_profile?.friends.count ?? 0) == 1 ? "" : "s"
        self.searchBar.prompt = "\(cur_user_profile?.friends.count ?? 0) Friend\(pluralString)"
    }
    
    func loadFriends() {
        self.friends = []
        for friend in cur_user_profile?.friends ?? [] {
            db_firestore.collection(friend.profileType).document(friend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    self.friends.append(fetchedProfile!)
                    self.filteredFriends = self.friends
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
            }
        }
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.filteredFriends = self.friends.filter{(profile: Profile) -> Bool in
                let containedInFirstName = profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                return containedInFirstName || containedInLastName
            }
        } else {
            self.filteredFriends = self.friends
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.friendCellIdentifier, for: indexPath as IndexPath) as! FriendTableViewCell
        let row = indexPath.row
        let friend = self.filteredFriends[row]
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
        
        let activeStreakCount = profile.subscribedStreaks.count
        self.streakLabel.textColor = UIColor(named: "Streakz_Grey")
        self.streakLabel.text = "\(activeStreakCount) Active Streakz"
    }
}
