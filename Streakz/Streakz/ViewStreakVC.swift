//
//  ViewStreakVC.swift
//  Streakz
//
//  Created by Zac Bonar on 3/22/21.
//

import UIKit

class ViewStreakVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var streakNumberDisplay: UILabel!
    @IBOutlet weak var subscribedDateDisplay: UILabel!
    @IBOutlet weak var buttonSubText: UILabel!
    @IBOutlet weak var markDoneButton: UIButton!
    @IBOutlet weak var streakTitleDisplay: UILabel!
    @IBOutlet weak var descriptionDisplay: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editStreakButton: UIBarButtonItem!
    
    var curUserProfile: Profile? = nil
    var streakSub: StreakSubscription!
    var relatedStreakPosts: [StreakPost]!
    
    var completeStreakSegueIdentifier = "ViewStreakSegueIdentifier"
    let privateStreakPostCellIdentifier = "PrivateStreakPostCellIdentifier"
    let editStreakSegueIdentifier = "EditStreakSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Get streak posts related to this streak subscription
        self.relatedStreakPosts = []
        for streakPost in cur_user_profile?.streakPosts ?? [] {
            if streakPost.streak.streakInfoId == streakSub.streakInfoId {
                self.relatedStreakPosts.append(streakPost)
            }
        }
        print("Related \(self.streakSub.name) Streak Posts: \(self.relatedStreakPosts.count)")
        self.tableView.reloadData()
        
        if streakSub.privacy != .Private {
            // remove "Edit Streak" button if not private streak
            editStreakButton.isEnabled = false
            editStreakButton.title = ""
        } else {
            editStreakButton.isEnabled = true
            editStreakButton.title = "Edit"
        }
        
        streakSub.listenStreakInfo { (streakInfo: StreakInfo?) in
            self.descriptionDisplay.text = streakInfo?.description
        }
        
        streakTitleDisplay.text = streakSub.name
        streakNumberDisplay.text = String(streakSub.streakNumber)
        subscribedDateDisplay.text = streakSub.subscriptionStartDate.shortDate
        
        if streakSub.canBeCompletedToday() {
            markDoneButton.isEnabled = true
            markDoneButton.setTitleColor(.systemBackground, for: .normal)
            markDoneButton.layer.borderWidth = 0.0
            markDoneButton.backgroundColor = UIColor(named: "Streakz_DarkRed")
            markDoneButton.setTitle("Mark done for today", for: .normal)

            let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: streakSub.nextDeadline())
            let hoursRemaining = diffComponents.hour!
            let minutesRemaining = diffComponents.minute!
            
            var timeRemainingString: String = String(hoursRemaining) + " hours remaining"

            if hoursRemaining == 1 {
                timeRemainingString = String(hoursRemaining) + " hour remaining"
            } else if hoursRemaining == 0 {
                if minutesRemaining > 1 {
                    timeRemainingString = String(minutesRemaining) + " minutes remaining"
                } else if minutesRemaining == 1 {
                    timeRemainingString = String(minutesRemaining) + " minute remaining"
                } else {
                    timeRemainingString = "Less than a minute left!"
                }
            }
            
            buttonSubText.text = timeRemainingString
        } else {
            markDoneButton.isEnabled = false
            markDoneButton.setTitleColor(UIColor(named: "Streakz_DarkRed"), for: .normal)
            markDoneButton.layer.borderColor = UIColor(named: "Streakz_DarkRed")?.cgColor
            markDoneButton.layer.borderWidth = 1.0
            markDoneButton.backgroundColor = .systemBackground
            markDoneButton.setTitle("Complete", for: .normal)
            
            if streakSub.wasCompletedToday() {
                buttonSubText.text = "Good Job keeping up your streak today!"
            } else {
                buttonSubText.text = "Come back on " + streakSub.nextStreakDate().fullDate
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let headerView = self.tableView.tableHeaderView else {
           return
        }
        
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        // Trigger a new layout only if the height has changed, otherwise it'd get stuck in a loop
        if headerView.frame.size.height != size.height {
           headerView.frame.size.height = size.height
           tableView.tableHeaderView = headerView
           tableView.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.relatedStreakPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.privateStreakPostCellIdentifier, for: indexPath as IndexPath) as! PrivateStreakPostCell
        let row = indexPath.row
        let streakPost = self.relatedStreakPosts[row]
        cell.styleCellWith(streakPost)
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == completeStreakSegueIdentifier, let nextVC = segue.destination as? CompleteStreakVC {
            nextVC.streakSub = streakSub
            nextVC.curUserProfile = curUserProfile
        } else if segue.identifier == editStreakSegueIdentifier, let destVC = segue.destination as? AddStreakVC {
            // inform Add Streak view controller that this is only an edit, not a new streak
            destVC.userIsEditing = true
            destVC.daysOfWeekSelected = streakSub.reminderDays
            destVC.curUserProfile = curUserProfile
            destVC.editStreakInfoId = streakSub.streakInfoId
        }
    }
}

class PrivateStreakPostCell: UITableViewCell {
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var datePostedLabel: UILabel!
    
    func styleCellWith(_ streakPost: StreakPost) {
        shadowView.backgroundColor = UIColor.clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowOffset = CGSize(width: 6, height: 6)
        shadowView.layer.shadowRadius = 2
        
        containerView.layer.borderWidth = 1.0
        containerView.layer.masksToBounds = false
        containerView.layer.borderColor = UIColor(named: "Streakz_LightRed")?.cgColor
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.clipsToBounds = true
        
        shadowView.layer.shouldRasterize = true
        shadowView.layer.rasterizationScale = UIScreen.main.scale

        countView.layer.borderWidth = 1.0
        countView.layer.masksToBounds = false
        countView.layer.borderColor = UIColor(named: "Streakz_Inverse")?.cgColor
        countView.layer.cornerRadius = countView.frame.size.width / 2
        countView.clipsToBounds = true

        if streakPost.image == "" {
            self.postImageView.image = UIImage(named: "StreakzLogo")
        } else {
            self.postImageView.load(url: URL(string: streakPost.image)!)
        }
        self.postImageView.clipsToBounds = true
        
        commentLabel.text = streakPost.postText
        countLabel.text = "\(streakPost.achievedStreak)"
        datePostedLabel.text = "\(streakPost.datePosted.fullDate)"
    }
}
