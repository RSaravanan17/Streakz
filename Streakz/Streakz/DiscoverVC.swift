//
//  DiscoverVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var discoverTableView: UITableView!
    
    let discoverStreakCellIdentifier = "DiscoverStreakCellIdentifier"
    
    var publicStreakz: [StreakInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.discoverTableView.delegate = self
        self.discoverTableView.dataSource = self

        // Do any additional setup after loading the view.
        loadPublicStreakz()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publicStreakz.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.discoverStreakCellIdentifier, for: indexPath as IndexPath) as! DiscoverStreakCell
        let row = indexPath.row
        let streak = self.publicStreakz[row]
        cell.styleView(streakInfo: streak)
        return cell
    }
    
    func loadPublicStreakz() {
        // fetch profile for current list of streaks from firebase
        if let collection = cur_user_collection, let user = cur_user_email {
            db_firestore.collection("public_streaks").whereField("viewability", isEqualTo: "Public")
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    
                    self.publicStreakz = documents.compactMap({ (QueryDocumentSnapshot) -> StreakInfo? in
                        return try? QueryDocumentSnapshot.data(as: StreakInfo.self)
                    })
                    
                    self.discoverTableView.reloadData()
                }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
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
