//
//  FriendInfoVC.swift
//  Streakz
//
//  Created by Michael on 4/22/21.
//

import UIKit

class FriendInfoVC: UIViewController {
    private lazy var friendsListVC: FriendsListVC = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "FriendsListVC") as! FriendsListVC

        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)

        return viewController
    }()

    private lazy var friendRequestsVC: FriendRequestsVC = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "FriendRequestsVC") as! FriendRequestsVC

        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)

        return viewController
    }()

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    var cameFromSearchFriends: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        self.segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBackground], for: .selected)
    }
    
    func setupView() {
        self.setupSegmentedControl()
        
        self.updateView()
    }
    
    func setupSegmentedControl() {
        // Configure Segmented Control
        self.segmentedControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)

        // Select First Segment
        self.segmentedControl.selectedSegmentIndex = cameFromSearchFriends ? 1 : 0
    }
    
    @objc func selectionDidChange(_ sender: UISegmentedControl) {
        self.updateView()
    }
    
    private func updateView() {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.remove(asChildViewController: friendRequestsVC)
            self.add(asChildViewController: friendsListVC)
        } else {
            self.remove(asChildViewController: friendsListVC)
            self.add(asChildViewController: friendRequestsVC)
        }
    }
    
    func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChild(viewController)
        
        self.containerView.addSubview(viewController.view)
                
        viewController.view.frame = self.containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        viewController.didMove(toParent: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParent()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
