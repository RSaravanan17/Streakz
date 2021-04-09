//
//  SearchFriendsViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 4/9/21.
//

import UIKit

class SearchFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var usersSearchBar: UISearchBar!
    @IBOutlet weak var usersTableView: UITableView!
    
    let userCellIdentifier = "UserCellIdentifier"
    
    var users: [Profile] = []
    var filteredUsers: [Profile] = []
    
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
                        
                        self.users += documents.compactMap({ (QueryDocumentSnapshot) -> Profile? in
                            return try? QueryDocumentSnapshot.data(as: Profile.self)
                        })
                        
                        self.filteredUsers = self.users
                        
                        self.usersTableView.reloadData()
                    }
            }
        }
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            // filter all user profiles that contain the search text (case-insensitive) in the first or last name
            self.filteredUsers = self.users.filter { (profile: Profile) -> Bool in
                let containedInFirstName = profile.firstName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInLastName = profile.lastName.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                
                return containedInFirstName || containedInLastName
            }
        } else {
            // when search text is empty, display all users
            self.filteredUsers = self.users
        }
        
        self.usersTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.userCellIdentifier, for: indexPath as IndexPath) as! UserStreakCell
        let row = indexPath.row
        let curProfile = self.filteredUsers[row]
        cell.styleView(profile: curProfile)
        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class UserStreakCell: UITableViewCell {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var mutualFriendCount: UILabel!
    @IBOutlet weak var sendFriendRequestButton: UIButton!
    
    var userProfile: Profile?
    
    func styleView(profile: Profile) {
        self.userProfile = profile
        
        self.backgroundColor = UIColor(named: "Streakz_Background")
        self.layer.cornerRadius = 20
        self.accessoryType = .disclosureIndicator
        
        self.userName.text = profile.firstName + " " + profile.lastName
        self.mutualFriendCount.text = "Friends: \(profile.friends.count)"
        
        self.sendFriendRequestButton.setTitle("Send Friend Request", for: .normal)
        self.sendFriendRequestButton.backgroundColor = UIColor.green
        self.sendFriendRequestButton.setTitleColor(UIColor.white, for: .normal)
        self.sendFriendRequestButton.layer.cornerRadius = 15
    }
    
    @IBAction func sendFriendRequestButtonPressed(_ sender: Any) {
        print("Just sent a friend request from \(cur_user_profile!.firstName) \(cur_user_profile!.lastName) [\(cur_user_profile!.accountType)] to \(self.userProfile!.firstName) \(self.userProfile!.lastName) [\(self.userProfile!.accountType)]")
    }
}
