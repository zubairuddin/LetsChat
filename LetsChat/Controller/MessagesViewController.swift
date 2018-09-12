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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutUser))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(showUsers))

        fetchCurrentUserAndSetNavbarTitle()
        
        //getAllMessagesFromFirebase()
        
        getAllMessagesForLoggedInUser()
    }
    
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
        
        var dictMessage = [String:Message]()
        
        guard let loggedInUserId = Auth.auth().currentUser?.uid  else {
            print("Unable to get logged-in user's id")
            return
        }
        
    
        let reference = Database.database().reference(withPath: "user-messages").child(loggedInUserId)
        reference.observe(.childAdded) { (snapshot) in
            print(snapshot)
            
            let messageId = snapshot.key
            let messagesNodeReference = Database.database().reference(withPath: "Messages").child(messageId)
            messagesNodeReference.observeSingleEvent(of: .value, with: { (snapshot) in
                print(snapshot)
                if let messageDict = snapshot.value as? [String:String] {
                    let messageObject = Message(dictionary: messageDict)
                    
                    //Instead of appending to array, we will create a dictionary and assign its values property to the array, this is done to show only the most recent message on the table view
                    
                    //self.arrMessages.append(messageObject)
                    
//                    if let toUserId = messageDict["toUserId"] {
//                        dictMessage[toUserId] = messageObject
//                    }
                    
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
                    
                    self.tblMessages.reloadData()
                }
            })
        }
    }
    
    func getAllMessagesFromFirebase() {
        
        var dictMessage = [String:Message]()
        let reference = Database.database().reference().child("Messages")
        reference.observe(.childAdded) { (snapshot) in
            if let messageDict = snapshot.value as? [String:String] {
                let messageObject = Message(dictionary: messageDict)
                
                //Instead of appending to array, we will create a dictionary and assign its values property to the array, this is done to show only the most recent message on the table view
                
                //self.arrMessages.append(messageObject)
                
                if let toUserId = messageDict["toUserId"] {
                    dictMessage[toUserId] = messageObject
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
                
                self.tblMessages.reloadData()
            }
        }
    }
    
    @objc func showUsers() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "UsersViewController") as! UsersViewController
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func logoutUser() {
        try! Auth.auth().signOut()
        navigationController?.popViewController(animated: true)
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrMessages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        
        //Get the username from toUserId
        //let toUserId = arrMessages[indexPath.row].toUserId
        
        let chatPartnerId: String!
        
        if arrMessages[indexPath.row].fromUserId == Auth.auth().currentUser?.uid {
            chatPartnerId = arrMessages[indexPath.row].toUserId
        }
        else {
            chatPartnerId = arrMessages[indexPath.row].fromUserId
        }
        
        let reference = Database.database().reference().child("Users").child(chatPartnerId)
        reference.observeSingleEvent(of: .value) { (snapshot) in
            print(snapshot)
            if let userDict = snapshot.value as? [String:String] {
                cell.lblTitle.text = userDict["name"]
                
                if let profileImageUrl = userDict["profileImageUrl"] {
                    if let imageUrl = URL(string: profileImageUrl) {
                        cell.imgUserImage.loadImageWithCachingFromUrl(imageUrl: imageUrl)
                    }
                }
            }
            
        }
        
        cell.lblSubTitle.text = arrMessages[indexPath.row].text
        
        //Convert timestamp string to double and then create a date from it
        
        if let doubleTimeStamp = Double(arrMessages[indexPath.row].timeStamp) {
            let timestampDate = Date(timeIntervalSince1970: doubleTimeStamp)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            
            let stringDate = dateFormatter.string(from: timestampDate)
            cell.lblTime.text = stringDate
            
        }
        
        
        return cell
    }
}
