//
//  OtherProfileVC.swift
//  Streakz
//
//  Created by Zac Bonar on 4/26/21.
//

import UIKit

enum FriendStatus : String, Codable {
    case AlreadyFriends
    case FriendRequestSent
    case TheyWantMe
    case Nothing
    case Error
}

func checkFriendStatus(otherProfileContainer: ProfileContainer) -> FriendStatus {
    guard let myProfile = cur_user_profile,
          let myProfileType = cur_user_collection,
          let myEmail = cur_user_email else {
        print("Problem checking friend status - cur_user data not set")
        return FriendStatus.Error
    }
    
    if myProfile.friends.contains(otherProfileContainer.baseProfile) {
        // already friends
        return FriendStatus.AlreadyFriends
    } else if otherProfileContainer.profile.friendRequests.contains(BaseProfile(profileType: myProfileType, email: myEmail)) {
        // friend request already sent
        return FriendStatus.FriendRequestSent
    } else if myProfile.friendRequests.contains(otherProfileContainer.baseProfile) {
        // they already sent me a request
        return FriendStatus.TheyWantMe
    } else {
        // I can send them a request
        return FriendStatus.Nothing
    }
}

class OtherProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var friendCountLabel: UILabel!
    @IBOutlet weak var streakPostTable: UITableView!

    @IBOutlet weak var friendsStatusView: UIStackView!
    @IBOutlet weak var friendStatusLabel: UILabel!
    @IBOutlet weak var friendButtonStackView: UIStackView!
    @IBOutlet weak var acceptFriendButton: UIButton!
    @IBOutlet weak var declineFriendButton: UIButton!
    @IBOutlet weak var sendRequestButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!
    
    var streakPosts: [StreakPost] = []
    var otherProfileContainer: ProfileContainer? = nil
    var friendStatus: FriendStatus? = nil
    
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
        
        updateFriendStatus()
        
        if let otherProf = otherProfileContainer?.profile {
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
    
    func updateFriendStatus() {
        guard let otherProfileCon = otherProfileContainer
               else {
            print("Problem loading friend status - it wasn't set by whoever called this VC")
            return
        }
        
        let otherProfile = otherProfileCon.profile
        let friendStatus = checkFriendStatus(otherProfileContainer: otherProfileCon)
        
        if friendStatus == FriendStatus.AlreadyFriends {
            friendStatusLabel.text = "You and \(otherProfile.firstName) are friends"
            friendButtonStackView.isHidden = true
        } else if friendStatus == FriendStatus.FriendRequestSent {
            friendStatusLabel.text = "You've sent \(otherProfile.firstName) a friend request"
            acceptFriendButton.isHidden = true
            declineFriendButton.isHidden = true
            sendRequestButton.isHidden = true
            cancelRequestButton.isHidden = false
        } else if friendStatus == FriendStatus.TheyWantMe {
            friendStatusLabel.text = "\(otherProfile.firstName) has sent you a friend request"
            acceptFriendButton.isHidden = false
            declineFriendButton.isHidden = false
            sendRequestButton.isHidden = true
            cancelRequestButton.isHidden = true
        } else {
            friendStatusLabel.text = "You're not friends with \(otherProfile.firstName)"
            acceptFriendButton.isHidden = true
            declineFriendButton.isHidden = true
            sendRequestButton.isHidden = false
            cancelRequestButton.isHidden = true
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
            destVC.posterProfile = otherProfileContainer?.profile
        }
    }

    @IBAction func acceptFriendRequest(_ sender: UIButton) {
        guard let myProfileType = cur_user_collection,
              let myEmail = cur_user_email,
              let myProfile = cur_user_profile,
              let friendToAccept = otherProfileContainer else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        
        
        print("Accepting Friend Request from \(friendToAccept.profile.firstName)")
        do {
            let dispatchGroup = DispatchGroup()
            
            // Add friend to this user's list of friends
            let myBaseProfile = BaseProfile(profileType: myProfileType, email: myEmail)
            myProfile.friends.append(friendToAccept.baseProfile)
            // Remove friend request from this users list of friend requests
            if let index = myProfile.friendRequests.firstIndex(of: friendToAccept.baseProfile) {
                myProfile.friendRequests.remove(at: index)
            } else {
                throw MyError.FoundNil
            }
            
            dispatchGroup.enter()
            try db_firestore.collection(myProfileType).document(myEmail).setData(from: myProfile) {_ in
                dispatchGroup.leave()
            }
            
            // Add this user to the other users list of friends
            let destination = friendToAccept.profile
            let destCollection = friendToAccept.baseProfile.profileType
            let destEmail = friendToAccept.baseProfile.email
            destination.friends.append(myBaseProfile)
            
            dispatchGroup.enter()
            try db_firestore.collection(destCollection).document(destEmail).setData(from: destination) {_ in
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                print("DEBUG: Successfully accepted friend request from \(friendToAccept.profile.firstName)")
                
                // Update friend status
                self.updateFriendStatus()
            })
            
        } catch let error {
            print("Error accepting friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues accepting the friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func declineFriendRequest(_ sender: UIButton) {
        guard let profileType = cur_user_collection,
              let email = cur_user_email,
              let friendToDecline = otherProfileContainer else {
            let alert = UIAlertController(
                title: "Invalid Session",
                message: "We're having trouble finding out who you are, please try signing out and signing back in",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        print("DEBUG: Declining Friend Request from \(friendToDecline.profile.firstName)")
        do {
            let updateUserProfile: Profile = cur_user_profile!
            // Remove friend request from this users list of friend requests
            if let index = updateUserProfile.friendRequests.firstIndex(of: friendToDecline.baseProfile) {
                updateUserProfile.friendRequests.remove(at: index)
            } else {
                throw MyError.FoundNil
            }
            try db_firestore.collection(profileType).document(email).setData(from: updateUserProfile) {_ in
                print("DEBUG: Successfully declined friend request from \(friendToDecline.profile.firstName)")
                
                // Update friend status
                self.updateFriendStatus()
            }
                        
            
        } catch let error {
            print("Error declining friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues declining the friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func sendFriendRequest(_ sender: UIButton) {
        
        guard let profileType = cur_user_collection,
              let email = cur_user_email,
              let otherProfileCon = otherProfileContainer else {
                let alert = UIAlertController(
                    title: "Invalid Session",
                    message: "We're having trouble finding out who you are, please try signing out and signing back in",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Send a friend request
        let requestSender = BaseProfile(profileType: profileType, email: email)
        let destination = otherProfileCon.profile
        let destCollection = otherProfileCon.baseProfile.profileType
        let destEmail = otherProfileCon.baseProfile.email
        destination.friendRequests.append(requestSender)
        do {
            print("DEBUG: Sending friend request")
            try db_firestore.collection(destCollection).document(destEmail).setData(from: destination) {_ in
                self.updateFriendStatus()
                print("DEBUG: Successfully sent friend request")
            }
        } catch let error {
            print("Error sending friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues sending your friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelFriendRequest(_ sender: UIButton) {
        guard let profileType = cur_user_collection,
              let email = cur_user_email,
              let otherProfileCon = otherProfileContainer else {
                let alert = UIAlertController(
                    title: "Invalid Session",
                    message: "We're having trouble finding out who you are, please try signing out and signing back in",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Remove pending friend request
        let requestSender = BaseProfile(profileType: profileType, email: email)
        let destination = otherProfileCon.profile
        let destCollection = otherProfileCon.baseProfile.profileType
        let destEmail = otherProfileCon.baseProfile.email
        
        do {
            if let index = destination.friendRequests.firstIndex(of: requestSender) {
                destination.friendRequests.remove(at: index)
            } else {
                throw MyError.FoundNil
            }
            
            print("DEBUG: Cancelling friend request")
            try db_firestore.collection(destCollection).document(destEmail).setData(from: destination) {_ in
                print("DEBUG: Succusfully canceled request")
                self.updateFriendStatus()
            }
        } catch let error {
            print("Error removing friend request: \(error)")
            let alert = UIAlertController(
                title: "Friend Request Error",
                message: "We ran into issues removing your friend request. Try again later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    enum MyError: Error {
        case FoundNil;
    }
}


