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
}

class ProfileVC: UIViewController, ProfileDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var userFriendsLabel: UILabel!
    @IBOutlet weak var streakPostsTable: UITableView!
    
    let signOutSegue = "SignOutSegue"
    let settingsSegue = "SettingsSegue"
    let streakPostSegue = "StreakPostIdentifier"
    let streakPostCell = "StreakPostCellIdentifier"
    var streakPosts: [StreakPost] = []
    var userProfile: Profile?
    var currentStreakPost: StreakPost?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        streakPostsTable.delegate = self
        streakPostsTable.dataSource = self
        setCurrentUser()
        
        // Round the profile image view
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.masksToBounds = false
        userImageView.layer.borderColor = UIColor(named: "Streakz_Inverse")?.cgColor
        userImageView.layer.cornerRadius = userImageView.frame.size.width / 2
        userImageView.clipsToBounds = true
        
        // TODO: remove this if we want to be able to select streakPosts and go to a ViewStreakPostVC
        //streakPostsTable.allowsSelection = false
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       return "Streak Posts:"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.contentView.backgroundColor = UIColor.systemBackground
        return view
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("clicked here")
//        self.selectedPostIndex = indexPath
//    }
    
    // allows rows to be deleted from the table
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let owner = cur_user_email,
               let collection = cur_user_collection,
               let curProfile = self.userProfile {
               
                let streakPost = self.streakPosts[indexPath.row]
                
                // remove current streak post from local list and user profile
                self.streakPosts.remove(at: indexPath.row)
                self.userProfile?.streakPosts = self.streakPosts
                
                // deletes the row in the tableView
                // can add animation if desired but need to fix TableCell corner rounding
                //tableView.deleteRows(at: [indexPath], with: .fade)
                
                // update Firebase
                do {
                    print("Attempting to delete Streak \(indexPath.row) for", cur_user_email!, "in", cur_user_collection!)
                    // update the user's profile in Firebase
                    try db_firestore.collection(collection).document(owner).setData(from: curProfile)
                    
                    navigationController?.popViewController(animated: true)
                } catch let error {
                    print("Error writing profile to Firestore: \(error)")
                }
            } else {
                print("Could not delete Streak \(indexPath.row)")
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func setCurrentUser() {
        if let collection = cur_user_collection, let user = cur_user_email {
            db_firestore.collection(collection).document(user)
                .addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    do {
                        let userProfile = try document.data(as: Profile.self)
                        self.userProfile = userProfile
                        // Set profile picture image view
                        if let imageURL: String = userProfile?.profilePicture {
                            if imageURL == "" {
                                self.userImageView.image = UIImage(named: "ProfileImageBlank")
                            } else {
                                self.userImageView.load(url: URL(string: imageURL)!)
                            }
                        } else {
                            self.userImageView.image = UIImage(named: "ProfileImageBlank")
                        }
                        // Set first and last name labels
                        if let firstName: String = userProfile?.firstName,
                           let lastName: String = userProfile?.lastName {
                            self.userNameLabel.text = "\(firstName) \(lastName)"
                        }
                        // Set the number of friends label
                        if let friendsCount: Int = userProfile?.friends.count {
                            self.userFriendsLabel.text = "\(friendsCount)"
                        } else {
                            self.userFriendsLabel.text = "0"
                        }
                        if let email = cur_user_email {
                            self.userInfoLabel.text = "EMAIL: " + email
                        }
                        // Set the streakPosts table
                        if var posts = userProfile?.streakPosts {
                            posts.sort(by: { $0.datePosted > $1.datePosted })
                            self.streakPosts = posts
                        } else {
//                            let dummyInfo = StreakInfo(owner: "Dummy", name: "Dummy streak", description: "", reminderDays: [false, false, false, false, false, false, false], viewability: .Private)
//                            let dummyStreak = StreakSubscription(streakInfo: dummyInfo, reminderTime: Date(), subscriptionStartDate: Date(), privacy: .Private)
//                            self.streakPosts = [StreakPost(for: dummyStreak, postText: "Error fetching streak posts", image: "")]
                        }
                        self.streakPostsTable.reloadData()

                    } catch let error {
                        print("Error deserializing data", error)
                    }
                }
        }
    }
    
    func getProfile() -> Profile? {
        return self.userProfile
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
        } else if segue.identifier == settingsSegue {
            if let destination = segue.destination as? SettingsVC {
                destination.profileDelegate = self as ProfileDelegate
            }
        } else if segue.identifier == streakPostSegue {
            let selectedIndex = self.streakPostsTable.indexPath(for: sender as! UITableViewCell)
            if let destination = segue.destination as? StreakPostScreenViewController {
                // set the current selected streak post
                self.currentStreakPost = self.streakPosts[selectedIndex!.row]
                destination.streakPostDelegate = self as ProfileVC
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
