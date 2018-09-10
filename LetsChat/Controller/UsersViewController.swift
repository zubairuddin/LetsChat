//
//  UsersViewController.swift
//  LetsChat
//
//  Created by Zubair on 08/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class UsersViewController: UIViewController {

    @IBOutlet weak var tblUsers: UITableView!
    var arrUsers = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Fetch users from firebase DB
        getUsersFromFirebase()
        
    }
    
    func getUsersFromFirebase() {
        //Get reference to the user DB
        let userDB = Database.database().reference().child("Users")
        
        //Observe the DB for any changes
        SVProgressHUD.show(withStatus: "Getting users...")
        SVProgressHUD.setDefaultMaskType(.black)
        
        userDB.observe(.childAdded) { (snapshot) in
            
            SVProgressHUD.dismiss()
            if let userDict = snapshot.value as? [String:String] {
                let userObject = User(userDict: userDict)
                userObject.id = snapshot.key
                
                self.arrUsers.append(userObject)

                DispatchQueue.main.async {
                    self.tblUsers.reloadData()
                }
            }
        }
    }

}

extension UsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrUsers.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        
        cell.lblTitle.text = arrUsers[indexPath.row].name
        cell.lblSubTitle.text = arrUsers[indexPath.row].email
        
        //Assign image to image view
        if let imageUrl = URL(string: self.arrUsers[indexPath.row].profileImageUrl) {
            cell.imgUserImage.loadImageWithCachingFromUrl(imageUrl: imageUrl)
        }

        return cell
    }
}
extension UsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.selectedUser = arrUsers[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
