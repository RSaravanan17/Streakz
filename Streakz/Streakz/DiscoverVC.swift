//
//  DiscoverVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var discoverSearchBar: UISearchBar!
    @IBOutlet weak var discoverTableView: UITableView!
    
    let discoverStreakCellIdentifier = "DiscoverStreakCellIdentifier"
    let viewPublicStreakSegueIdentifier = "ViewPublicStreakSegueIdentifier"
    let sectionTitles = ["Friends", "Friends' Public", "Public"]
    
    // Store lists of tuples so we can map Streak ID to StreakInfo object
    // First list contains Friends-related Streakz
    // Second list contains Friends-related Public Streakz
    // Third list contains remaining Public Streakz
    var publicStreakz: [[(String, StreakInfo)]] = [[], [], []]
    var filteredPublicStreakz: [[(String, StreakInfo)]] = [[], [], []]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.discoverSearchBar.delegate = self
        self.discoverTableView.delegate = self
        self.discoverTableView.dataSource = self

        loadPublicStreakz()
    }
    
    func loadPublicStreakz() {
        // fetch current list of friend's streaks from Firebase
        if let _ = cur_user_collection, let _ = cur_user_email {
            db_firestore.collection("friends_streaks").whereField("owner", in: cur_user_profile!.getBasicFriendsList())
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }

                    // clear out all Friends streakz
                    self.publicStreakz[0].removeAll()
                    
                    // add each streak to the Friends section
                    self.publicStreakz[0] = documents.compactMap({ (queryDocumentSnapshot) -> (String, StreakInfo)? in
                        let documentID: String = queryDocumentSnapshot.documentID
                        let streak: StreakInfo? = try? queryDocumentSnapshot.data(as: StreakInfo.self)
                        return (documentID, streak) as? (String, StreakInfo)
                    })

                    self.filteredPublicStreakz = self.publicStreakz

                    self.discoverTableView.reloadData()
                }
        }
        
        // fetch current list of public streaks from Firebase
        if let _ = cur_user_collection, let _ = cur_user_email {
            db_firestore.collection("public_streaks").whereField("viewability", isEqualTo: "Public")
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    
                    // clear out all Public streakz
                    self.publicStreakz[1].removeAll()
                    self.publicStreakz[2].removeAll()
                    
                    for document in documents {
                        let documentID: String = document.documentID
                        let streak: StreakInfo? = try? document.data(as: StreakInfo.self)
                        
                        // add each streak to the appropriate section based on whether the owner is in the friend's list of the current user
                        if (cur_user_profile!.friends.contains(BaseProfile(profileType: streak!.owner[1], email: streak!.owner[0]))) {
                            self.publicStreakz[1].append(((documentID, streak) as? (String, StreakInfo))!)
                        } else {
                            self.publicStreakz[2].append(((documentID, streak) as? (String, StreakInfo))!)
                        }
                    }
                    
                    self.filteredPublicStreakz = self.publicStreakz
                    
                    self.discoverTableView.reloadData()
                }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        discoverSearchBar.setShowsCancelButton(true, animated: true)
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            // filter all streakz in all 3 sections that contain the search text (case-insensitive) in the name or description
            for i in 0...2 {
                self.filteredPublicStreakz[i] = self.publicStreakz[i].filter { (streakWithID: (String, StreakInfo)) -> Bool in
                    let streak = streakWithID.1
                    let containedInStreakName = streak.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                    let containedInStreakDesc = streak.description.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                    
                    return containedInStreakName || containedInStreakDesc
                }
            }
        } else {
            // when search text is empty, display all streakz
            self.filteredPublicStreakz = self.publicStreakz
        }
        
        self.discoverTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        discoverSearchBar.setShowsCancelButton(false, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPublicStreakz[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredPublicStreakz.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.filteredPublicStreakz[section].count > 0 ? sectionTitles[section] : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.discoverStreakCellIdentifier, for: indexPath as IndexPath) as! DiscoverStreakCell
        let streakWithID = self.filteredPublicStreakz[indexPath.section][indexPath.row]
        cell.styleView(streakWithID: streakWithID)
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.viewPublicStreakSegueIdentifier,
           let nextVC = segue.destination as? ViewPublicStreakVC,
           let indexPath = discoverTableView.indexPathForSelectedRow {
            nextVC.publicStreak = self.filteredPublicStreakz[indexPath.section][indexPath.row].1
            discoverTableView.deselectRow(at: indexPath, animated: false)
        }
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

class DiscoverStreakCell: UITableViewCell {
    
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var numParticipantsLabel: UILabel!
    @IBOutlet weak var numFriendsLabel: UILabel!
    
    func styleView(streakWithID: (String, StreakInfo)) {
        self.backgroundColor = UIColor(named: "Streakz_Background")
        self.layer.cornerRadius = 20
        self.accessoryType = .disclosureIndicator
        
        let streakID = streakWithID.0
        let streakInfo = streakWithID.1
        
        self.titleLabel.text = streakInfo.name
        self.numParticipantsLabel.text = "\(streakInfo.subscribers.count) Participants"
        
        var numFriends = 0
        
        // count how many friends are subbed
        for friend in cur_user_profile?.friends ?? [] {
            db_firestore.collection(friend.profileType).document(friend.email).getDocument {
                (document, error) in
                let result = Result {
                    try document?.data(as: Profile.self)
                }
                switch result {
                case .success(let fetchedProfile):
                    if let fetchedProfile = fetchedProfile {
                        for streak in fetchedProfile.subscribedStreaks {
                            if streak.streakInfoId == streakID {
                                numFriends += 1
                                break
                            }
                        }
                    }
                case .failure(let error):
                    print("Error fetching a profile on discover screen: \(error)")
                }
                self.numFriendsLabel.text = String(numFriends) + " friends"
            }

        }
        
    }
}
