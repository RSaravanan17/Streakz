//
//  FriendsVC.swift
//  Streakz
//
//  Created by Michael on 3/17/21.
//

import UIKit

class FriendPostContainer {
    
    let friendName: String
    let streakPost: StreakPost
    
    init(friendName: String, streakPost: StreakPost) {
        self.friendName = friendName
        self.streakPost = streakPost
    }
}

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var friendsFeedTable: UITableView!
    
    let searchFriendsSegueIdentifier = "SearchFriendsSegueIdentifier"
    let streakPostCell = "FriendStreakPostCellIdentifier"
    let streakPostSegue = "StreakPostIdentifier"
    let viewStreakPostSegueIdentifier = "ViewStreakPost"
    var streakPosts: [FriendPostContainer] = []
    let refreshControl = UIRefreshControl()
    var selectedStreakPost: FriendPostContainer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        friendsFeedTable.delegate = self
        friendsFeedTable.dataSource = self
        
        friendsFeedTable.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        
        loadPosts()
    }
    
    func loadPosts() {
        if let profile = cur_user_profile {
            for friend in profile.friends {
                db_firestore.collection(friend.profileType).document(friend.email).getDocument {
                    (document, error) in
                    let result = Result {
                        try document?.data(as: Profile.self)
                    }
                    switch result {
                    case .success(let fetchedProfile):
                        if let friendProfile = fetchedProfile {
                            for post in friendProfile.streakPosts.filter( { $0.streak.privacy != .Private } ) {
                                let name = "\(friendProfile.firstName) \(friendProfile.lastName)"
                                self.streakPosts.append(FriendPostContainer(friendName: name, streakPost: post))
                            }
                            self.streakPosts.sort(by: { $0.streakPost.datePosted > $1.streakPost.datePosted })
                            self.friendsFeedTable.reloadData()
                        }
                    case .failure(let error):
                        print("Error fetching a friend's profile for friends feed: \(error)")
                    }
                }
            }
        } else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // function for refreshing table view with new data
    @objc func refresh(_ sender: UIRefreshControl) {
        streakPosts = []
        loadPosts()
        sender.endRefreshing()
        friendsFeedTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if streakPosts.count == 0 {
            friendsFeedTable.setEmptyMessage("Your friends haven't made any\npublic or friend's-only posts!")
        } else {
            friendsFeedTable.restore()
        }
        return streakPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: streakPostCell, for: indexPath as IndexPath) as! FriendStreakPostCell
        let row = indexPath.row
        let postContainer = streakPosts[row]
        cell.styleView(postContainer: postContainer)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedStreakPost = streakPosts[indexPath.row]
        performSegue(withIdentifier: viewStreakPostSegueIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == viewStreakPostSegueIdentifier, let destVC = segue.destination as? ViewStreakPostVC {
            destVC.streakPost = selectedStreakPost?.streakPost
            destVC.posterNameStr = selectedStreakPost?.friendName
        }
    }
    
    func acceptFriendRequest(otherBaseProf: BaseProfile) {
        guard let myProfileType = cur_user_collection,
              let myEmail = cur_user_email,
              let myProfile = cur_user_profile,
              let indexOfRequest = myProfile.friendRequests.firstIndex(of: otherBaseProf) else {
            
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Get other profile from firebase
        db_firestore.collection(otherBaseProf.profileType).document(otherBaseProf.email).getDocument {
            (document, error) in
            if let document = document, document.exists {
                do {
                    let otherProfile = try document.data(as: Profile.self)!
                    
                    // Add yourself on the other profile's friend list
                    let myBaseProfile = BaseProfile(profileType: myProfileType, email: myEmail)
                    otherProfile.friends.append(myBaseProfile)
                    do {
                        try db_firestore.collection(otherBaseProf.profileType).document(otherBaseProf.email).setData(from: otherProfile)
                        
                        // Remove the other profile from your pending requests list
                        myProfile.friendRequests.remove(at: indexOfRequest)
                        
                        // Add other profile to your friends list
                        myProfile.friends.append(otherBaseProf)
                        
                        // update my profile in Firebase
                        do {
                            print("Attempting to update profile for", myEmail, "in", myProfileType)
                            try db_firestore.collection(myProfileType).document(myEmail).setData(from: myProfile)
                        } catch let error {
                            print("This is a critical error. We've added ourselves as someone's friend, but we can't update our own friends list because: Error writing profile to Firestore: \(error)")
                        }
                          
                    } catch let error {
                        print("Error accepting friend request: \(error)")
                        let alert = UIAlertController(
                            title: "Friend Request Error",
                            message: "We ran into issues accepting that friend request. Try again later",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    
                } catch {
                    print("Error deserializing profile - trying to get profile who sent me a friend request")
                }
            } else {
                print("Error fetching document")
            }
        }
    }
}

class FriendStreakPostCell: UITableViewCell {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var posterLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    
    func styleView(postContainer: FriendPostContainer) {
        let streakPost = postContainer.streakPost
        view.layer.cornerRadius = 20
        self.selectionStyle = .none
        posterLabel.text = postContainer.friendName
        titleLabel.text = streakPost.streak.name
        numberLabel.text = "Streak: \(streakPost.achievedStreak)"
        descriptionLabel.text = streakPost.postText
        descriptionLabel.numberOfLines = 4
        
//        if streakPost.image.isEmpty {
//            self.postImage.image = UIImage(named: "StreakzLogo")
//        } else {
//            self.postImage.load(url: URL(string: streakPost.image)!)
//        }
        // until bug with image is fixed:
        self.postImage.image = UIImage(named: "StreakzLogo")
    }
}
