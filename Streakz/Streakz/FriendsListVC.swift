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
    let otherProfileSegue = "ShowOtherProfileSegue"
    
    var friends: [ProfileContainer] = []
    var filteredFriends: [ProfileContainer] = []
    
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
        let dispatchGroup = DispatchGroup()
        for friend in cur_user_profile?.friends ?? [] {
            dispatchGroup.enter()
            db_firestore.collection(friend.profileType).document(friend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    if let profile = fetchedProfile {
                        print("DEBUG: I, \(cur_user_profile!.firstName) am friends with \(profile.firstName)")
                        self.friends.append(ProfileContainer(baseProfile: friend, profile: profile))
                    } else {
                        print("Error fetching profile on discover screen:")
                    }
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main, execute: {
            print("DEBUG: Fetched all friends")
            self.filteredFriends = self.friends
            self.filteredFriends.sort(by: { $0.profile.firstName < $1.profile.firstName })
            self.tableView.reloadData()
        })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.filteredFriends = self.friends.filter{(profileContainer: ProfileContainer) -> Bool in
                let containedInFirstName = profileContainer.profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profileContainer.profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == otherProfileSegue,
            let destination = segue.destination as? OtherProfileVC,
            let selectedIndexPath = tableView.indexPathForSelectedRow,
            let cell = tableView.cellForRow(at: selectedIndexPath) as? FriendTableViewCell {

            destination.otherProfileContainer = cell.profileContainer
        }
    }
    
}

class FriendTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var streakLabel: UILabel!
    
    var profileContainer: ProfileContainer? = nil

    
    func styleViewWith(_ profileContainer: ProfileContainer) {
        // Style image view
        self.profileImage.layer.borderWidth = 1.0
        self.profileImage.layer.masksToBounds = false
        self.profileImage.layer.borderColor = UIColor(named: "Streakz_Grey")?.cgColor
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2
        self.profileImage.clipsToBounds = true
        
        // Set fields
        self.profileContainer = profileContainer
        let profile = profileContainer.profile
        
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
