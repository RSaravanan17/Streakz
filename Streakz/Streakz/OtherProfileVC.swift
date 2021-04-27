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
    let viewStreakPostSegueIdentifier = "ViewStreakPostSegue"
    
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
            userNameLabel.text = "\(otherProf.firstName) \(otherProf.lastName)"
            friendCountLabel.text = String(otherProf.friends.count)

            if otherProf.profilePicture != "",
               let imageURL = (URL(string: otherProf.profilePicture))  {
                profileImage.load(url: imageURL)
            } else {
                profileImage.image = UIImage(named: "ProfileImageBlank")
            }
            
            // Don't show private streak posts
            streakPosts = []
            for post in otherProf.streakPosts.filter( { $0.streak.privacy != .Private } ) {
                self.streakPosts.append(post)
            }
            self.streakPosts.sort(by: { $0.datePosted > $1.datePosted })
            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewStreakPostSegueIdentifier,
           let destVC = segue.destination as? ViewStreakPostVC,
           let postIndex = streakPostTable.indexPathForSelectedRow?.row {
            destVC.streakPost = streakPosts[postIndex]
            destVC.posterProfile = otherProfile
        }
    }

}


