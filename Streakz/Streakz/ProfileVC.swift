//
//  ProfileVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import Firebase

// Extension of UIImageView class: function used to load a remote URL image
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

protocol ProfileDelegate {
    func getProfile() -> Profile?
    func setCurrentUser(profileInput: Profile?)
}

class ProfileVC: UIViewController, ProfileDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userFriendsLabel: UILabel!
    @IBOutlet weak var streakPostsTable: UITableView!
    
    let signOutSegue = "SignOutSegue"
    let settingsSegue = "SettingsSegue"
    let streakPostSegue = "StreakPostIdentifier"
    let streakPostCell = "StreakPostCellIdentifier"
    var streakPosts: [StreakPost] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        streakPostsTable.delegate = self
        streakPostsTable.dataSource = self
        
        // Round the profile image view
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.masksToBounds = false
        userImageView.layer.borderColor = UIColor(named: "Streakz_Inverse")?.cgColor
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        setCurrentUser(profileInput: cur_user_profile)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if streakPosts.count == 0 {
            streakPostsTable.setEmptyMessage("Complete a streak to add streak posts!")
        } else {
            streakPostsTable.restore()
        }
        return streakPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: streakPostCell, for: indexPath as IndexPath) as! StreakPostCell
        let row = indexPath.row
        let streakPost = streakPosts[row]
        cell.styleView(streakPost: streakPost)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       return "Streak Posts:"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.contentView.backgroundColor = UIColor.systemBackground
        return view
    }
    
    
    // allows rows to be deleted from the table
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let email = cur_user_email,
               let collection = cur_user_collection,
               let curProfile = cur_user_profile {
               
                
                // remove current streak post from local list and user profile
                self.streakPosts.remove(at: indexPath.row)
                curProfile.streakPosts = self.streakPosts
                
                // update Firebase
                do {
                    print("Attempting to delete Streak \(indexPath.row) for", cur_user_email!, "in", cur_user_collection!)
                    // update the user's profile in Firebase
                    try db_firestore.collection(collection).document(email).setData(from: curProfile) {_ in
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch let error {
                    print("Error writing profile to Firestore: \(error)")
                }
            } else {
                print("Could not delete Streak \(indexPath.row)")
            }
        }
    }
    
    func setCurrentUser(profileInput: Profile?) {
        if let curProfile = profileInput {
            // Set profile picture image view
            let imageURL: String = curProfile.profilePicture
            if imageURL == "" {
                self.userImageView.image = UIImage(named: "ProfileImageBlank")
            } else {
                self.userImageView.load(url: URL(string: imageURL)!)
            }
            
            // Set first and last name labels
            self.userNameLabel.text = "\(curProfile.firstName) \(curProfile.lastName)"

            // Set the number of friends label
            self.userFriendsLabel.text = "\(curProfile.friends.count)"
            
            // Set the streakPosts table
            var posts = curProfile.streakPosts
            posts.sort(by: { $0.datePosted > $1.datePosted })
            self.streakPosts = posts
            
            self.streakPostsTable.reloadData()
        }
    }
    
    func getProfile() -> Profile? {
        return cur_user_profile
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == signOutSegue {
            // sign out email user
            do { try Auth.auth().signOut() }
            catch { print("Email user already logged out") }
            
            // sign out Google user
            GIDSignIn.sharedInstance().signOut()
            
            // sign out Facebook user
            let loginManager = LoginManager()
            loginManager.logOut()
            
            if let listener = cur_user_profile_listener {
                print("DEBUG: Releasing previous profile listener...")
                listener.remove()
            }
            
            cur_user_profile_listener = nil
            cur_user_profile = nil

        } else if segue.identifier == settingsSegue {
            if let destination = segue.destination as? SettingsVC {
                destination.profileDelegate = self as ProfileDelegate
            }
        } else if segue.identifier == streakPostSegue {
            
            if let destination = segue.destination as? ViewStreakPostVC,
               let selectedIndex = self.streakPostsTable.indexPath(for: sender as! UITableViewCell) {
            
                // use the current selected streak post
                destination.streakPost = self.streakPosts[selectedIndex.row]
                
                // Don't need to set posterNameStr, if left nil it'll use current user which is what we want
                
                // Deselect the chosen StreakPost to get rid of the weird grey highlight
                self.streakPostsTable.deselectRow(at: selectedIndex, animated: false)
            }
        }
    }
}

class StreakPostCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var streakNumberLabel: UILabel!
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postComment: UILabel!
    
    func styleView(streakPost: StreakPost) {
        titleLabel?.text = streakPost.streak.name
        streakNumberLabel?.text = "Streak: \(streakPost.achievedStreak)"
        view.layer.cornerRadius = 20
        postComment.text = streakPost.postText
        postComment.numberOfLines = 4
        
        if streakPost.image == "" {
            self.postImage.image = UIImage(named: "StreakzLogo")
        } else {
            self.postImage.load(url: URL(string: streakPost.image)!)
        }
    }
}
