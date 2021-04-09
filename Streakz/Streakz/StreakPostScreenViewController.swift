//
//  StreakPostScreenViewController.swift
//  Streakz
//
//  Created by Rithvik Saravanan on 4/9/21.
//

import UIKit

class StreakPostScreenViewController: UIViewController {

    @IBOutlet weak var streakTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var streakDescription: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    
    var streakPostDelegate: ProfileVC! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // allows for unlimited number of lines for labels
        self.streakTitle.numberOfLines = 0
        self.postNumber.numberOfLines = 0
        self.streakDescription.numberOfLines = 0
        
        // assign the labels to the appropriate fields from the current streak post
        self.streakTitle.text = self.streakPostDelegate.currentStreakPost!.streak.name
        self.postNumber.text = "Streak: \(self.streakPostDelegate.currentStreakPost!.achievedStreak)"
        self.streakDescription.text = self.streakPostDelegate.currentStreakPost!.postText
        self.postImage.image = UIImage(named: "StreakzLogo")
        if self.streakPostDelegate.currentStreakPost!.image == "" {
            self.postImage.image = UIImage(named: "StreakzLogo")
        } else {
            self.postImage.load(url: URL(string: self.streakPostDelegate.currentStreakPost!.image)!)
        }
    }

}
