//
//  MessagesViewController.swift
//  LetsChat
//
//  Created by Zubair on 08/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
class MessagesViewController: UIViewController {

    @IBOutlet weak var tblMessages: UITableView!
    
    var arrMessages = [Message]()
    
    //MARK: - View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutUser))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(showUsers))

        fetchCurrentUserAndSetNavbarTitle()
        
        //getAllMessagesFromFirebase()
        
        getAllMessagesForLoggedInUser()
    }
    
    //MARK: - Local methods
    func fetchCurrentUserAndSetNavbarTitle() {
        
        //Get user id of logged-in user
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Unable to fetch user.")
            return
        }
        
        //Get reference to current logged-in user in DB
        let reference = Database.database().reference().child("Users").child(userId)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if let currentUser = snapshot.value as? [String:String] {
                self.title = currentUser["name"]
            }
            
        }, withCancel: nil)
        
    }
    
    func getAllMessagesForLoggedInUser() {
        
        //Create a dict to show only the latest message on the Messages screen,
        var dictMessage = [String:Message]()
        
        guard let loggedInUserId = Auth.auth().currentUser?.uid  else {
            print("Unable to get logged-in user's id")
            return
        }
        
        //SVProgressHUD.show()
        
        let reference = Database.database().reference(withPath: "user-messages").child(loggedInUserId)
        reference.observe(.childAdded) { (snapshot) in
            
            let messageId = snapshot.key
            
            Database.database().reference(withPath: "Messages").child(messageId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                print(snapshot)
                
                if let messageDict = snapshot.value as? [String:String] {
                    
                    let messageObject = Message(dictionary: messageDict)
                    
                    //Instead of appending to array, we will create a dictionary and assign its values property to the array, this is done to show only the most recent message on the table view
                    
                    //self.arrMessages.append(messageObject)
                    
                
                    if let chatPartnerId = messageObject.chatPartnerId {
                        dictMessage[chatPartnerId] = messageObject
                    }
                    
                    self.arrMessages = Array(dictMessage.values)

                    //******************************************//
                    
                    //Sort the messages in descending order, i.e. show the latest message first
                    let sortedMessages = self.arrMessages.sorted(by: { (message1, message2) -> Bool in
                        let firstMessageTimestamp = Double(message1.timeStamp)!
                        let secondMessageTimestamp = Double(message2.timeStamp)!
                        
                        return firstMessageTimestamp > secondMessageTimestamp
                    })
                    
                    
                    self.arrMessages = sortedMessages
                    
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        self.tblMessages.reloadData()
                    }
                }
            })
        }
    }
    
    @objc func showUsers() {
        
        //Change back button title, this needs to be done before pushing
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed

        let vc = storyboard?.instantiateViewController(withIdentifier: "UsersViewController") as! UsersViewController
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func logoutUser() {
        try! Auth.auth().signOut()
        navigationController?.popViewController(animated: true)
    }
    
    func setUpNameAndProfileImage(forCell cell: UserCell, chatPartnerId: String) {
        let reference = Database.database().reference().child("Users").child(chatPartnerId)
        reference.observeSingleEvent(of: .value) { (snapshot) in
            //print(snapshot)
            if let userDict = snapshot.value as? [String:String] {
                print("User dict is, ",userDict)
                cell.lblTitle.text = userDict["name"]
                
                if let profileImageUrl = userDict["profileImageUrl"] {
                    if let imageUrl = URL(string: profileImageUrl) {
                        cell.imgUserImage.loadImageWithCachingFromUrl(imageUrl: imageUrl)
                    }
                }
            }
            
        }
    }
    
    func showMessageDateTime(forIndex index:Int, cell: UserCell) {
        if let doubleTimeStamp = Double(arrMessages[index].timeStamp) {
            let timestampDate = Date(timeIntervalSince1970: doubleTimeStamp)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            
            let stringDate = dateFormatter.string(from: timestampDate)
            cell.lblTime.text = stringDate
            
        }
    }
    func getDetailOfChatPartnerAndShowChatLog(chatPartnerId:String) {
        
        Database.database().reference().child("Users").child(chatPartnerId).observeSingleEvent(of: .value) { (snapshot) in
        guard let dict = snapshot.value as? [String:String] else {
        return
        }
    
        let user = User(userDict: dict)
        user.id = chatPartnerId
    
        //Change back button title, this needs to be done before pushing
        let backItem = UIBarButtonItem()
        backItem.title = ""
        self.navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.selectedUser = user
        self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//MARK: - UITableView Datasource
extension MessagesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        
        cell.imgUserImage.layer.cornerRadius = cell.imgUserImage.frame.size.width / 2
        cell.imgUserImage.layer.masksToBounds = true
        
        let chatPartnerId: String!
        
        if arrMessages[indexPath.row].fromUserId == Auth.auth().currentUser?.uid {
            chatPartnerId = arrMessages[indexPath.row].toUserId
        }
        else {
            chatPartnerId = arrMessages[indexPath.row].fromUserId
        }
        
        cell.lblSubTitle.text = arrMessages[indexPath.row].text
        
        //Set up name and profile image of chat partner
        setUpNameAndProfileImage(forCell: cell, chatPartnerId: chatPartnerId)
        
        //Convert timestamp string to double and then create a date from it
        showMessageDateTime(forIndex: indexPath.row, cell: cell)
    
        return cell
    }
}

//MARK: - UITableView Delegate
extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let message = arrMessages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId else {
            return
        }
        
        //Get detail of the chat partner from Users node and show chat log for that user
        getDetailOfChatPartnerAndShowChatLog(chatPartnerId: chatPartnerId)
    }
}
