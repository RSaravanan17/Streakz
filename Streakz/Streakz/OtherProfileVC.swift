//
//  OtherProfileVC.swift
//  Streakz
//
//  Created by Zac Bonar on 4/26/21.
//

import UIKit

class OtherProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var friendCountLabel: UILabel!
    @IBOutlet weak var streakPostTable: UITableView!
    
    var streakPosts: [StreakPost] = []
    var otherProfile: Profile? = nil
    
    let streakPostCell = "StreakPostCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        streakPostTable.delegate = self
        streakPostTable.dataSource = self
        
        profileImage.layer.borderWidth = 1.0
        profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor(named: "Streakz_Inverse")?.cgColor
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        
        if let otherProf = otherProfile {
            streakPosts = otherProf.streakPosts
            
            userNameLabel.text = "\(otherProf.firstName) \(otherProf.lastName)"

            if otherProf.profilePicture != "",
               let imageURL = (URL(string: otherProf.profilePicture))  {
                profileImage.load(url: imageURL)
            } else {
                profileImage.image = UIImage(named: "ProfileImageBlank")
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streakPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: streakPostCell, for: indexPath as IndexPath) as! StreakPostCell
        let row = indexPath.row
        let streakPost = streakPosts[row]
        cell.styleView(streakPost: streakPost)
        return cell
    }

}


