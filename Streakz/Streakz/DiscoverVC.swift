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
    
    var publicStreakz: [StreakInfo] = []
    var filteredPublicStreakz: [StreakInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.discoverSearchBar.delegate = self
        self.discoverTableView.delegate = self
        self.discoverTableView.dataSource = self

        // Do any additional setup after loading the view.
        loadPublicStreakz()
    }
    
    func loadPublicStreakz() {
        // fetch profile for current list of streaks from Firebase
        if let _ = cur_user_collection, let _ = cur_user_email {
            db_firestore.collection("public_streaks").whereField("viewability", isEqualTo: "Public")
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    
                    self.publicStreakz = documents.compactMap({ (QueryDocumentSnapshot) -> StreakInfo? in
                        return try? QueryDocumentSnapshot.data(as: StreakInfo.self)
                    })
                    
                    self.filteredPublicStreakz = self.publicStreakz
                    
                    self.discoverTableView.reloadData()
                }
        }
    }
    
    // filters the table according to the search text
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            // filter all public streakz that contain the search text (case-insensitive) in the name or description
            self.filteredPublicStreakz = self.publicStreakz.filter { (streak: StreakInfo) -> Bool in
                let containedInStrealName = streak.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                let containedInStreakDesc = streak.description.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
                
                return containedInStrealName || containedInStreakDesc
            }
        } else {
            // when search text is empty, display all streakz
            self.filteredPublicStreakz = self.publicStreakz
        }
        
        self.discoverTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPublicStreakz.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.discoverStreakCellIdentifier, for: indexPath as IndexPath) as! DiscoverStreakCell
        let row = indexPath.row
        let streak = self.filteredPublicStreakz[row]
        cell.styleView(streakInfo: streak)
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.viewPublicStreakSegueIdentifier,
           let nextVC = segue.destination as? ViewPublicStreakVC,
           let indexPath = discoverTableView.indexPathForSelectedRow {
            let row = indexPath.row
            nextVC.publicStreak = self.filteredPublicStreakz[row]
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
    
    func styleView(streakInfo: StreakInfo) {
        self.backgroundColor = UIColor(named: "Streakz_Background")
        self.layer.cornerRadius = 20
        self.accessoryType = .disclosureIndicator
        
        self.titleLabel.text = streakInfo.name
        self.numParticipantsLabel.text = "\(streakInfo.subscribers.count) Participants"
        self.numFriendsLabel.text = "100 friends"
    }
}
