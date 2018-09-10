//
//  ChatViewController.swift
//  LetsChat
//
//  Created by Zubair on 02/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tblMessages: UITableView!
    @IBOutlet weak var txtMessage: UITextField!
    @IBOutlet weak var btnSendMessage: UIButton!
    @IBOutlet weak var viewTypeMessageBottom: NSLayoutConstraint!

    var selectedUser: User? {
        didSet {
            navigationItem.title = selectedUser?.name
        }
    }
    
    var arrMessages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Get the stored messages from Firebase DB
        getMessagesFromFirebase()
        
        //Adding notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        handleSendMessage(toUser: selectedUser!)
    }
    
    func handleSendMessage(toUser: User) {
        
        let messagesDB = Database.database().reference().child("Messages")
        let date = Date().timeIntervalSince1970
        
        let timeStamp = String(date)
        
        guard let fromUserId = Auth.auth().currentUser?.uid else {
            print("Current user id not available")
            return
        }
        
        let dictMessage = ["toUserId": toUser.id, "fromUserId":fromUserId, "text": txtMessage.text!, "timestamp": timeStamp]
        
        let childMessage = messagesDB.childByAutoId()
        childMessage.setValue(dictMessage) { (error, reference) in
            
            if error != nil {
                print("An error occured while saving \(error!.localizedDescription)")
                return
            }
            
            print("Message saved successfully in Messages node")
            
            //Get the key of auto generated child node above
            let messageId = childMessage.key
            
            //Get a new reference for from user
            let fromUserReference = Database.database().reference(withPath: "user-messages").child(fromUserId)
            fromUserReference.updateChildValues([messageId:1], withCompletionBlock: { (error, snapshot) in
                if error != nil {
                    return
                }
                
                print(snapshot)
            })
            
            //Get a new reference for to user
            let toUserReference = Database.database().reference(withPath: "user-messages").child(toUser.id)
            toUserReference.updateChildValues([messageId:1], withCompletionBlock: { (error, snapshot) in
                if error != nil {
                    return
                }
                
                print(snapshot)
            })
        }
    }
    
    func getMessagesFromFirebase() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        //Get reference of our DB
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid)
        
        //Observe the DB for any changes
        userMessagesRef.observe(.childAdded) { (snapshot) in
            
            let messageId = snapshot.key
            
            let messagesRef = Database.database().reference().child("Messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                //Get the dictionary that we stored while sending the message
                let dictMessage = snapshot.value as! [String:String]
                
                //Instantiate Message object
                let messageObject = Message(dictionary: dictMessage)

                if messageObject.chatPartnerId == self.selectedUser?.id {
                    //Add the message object to arrMessages
                    self.arrMessages.append(messageObject)
                    
                    //Reload the table
                    self.tblMessages.reloadData()

                }
            })
        }
    }
    
    //Keyboard handling method
    @objc func keyBoardWillChange(notification:NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                print(keyboardFrame)
                
                let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
                viewTypeMessageBottom.constant = isKeyboardShowing ? keyboardFrame.height : 0
                
                UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    //Scroll to last row of tableview
                    if isKeyboardShowing {
                        //self.scrollToLastRow()
                    }
                })
            }
        }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrMessages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        let message = arrMessages[indexPath.row]
        
        //Detect if the message was sent or received
        
        if message.fromUserId == Auth.auth().currentUser!.uid {
            //Message was sent
        }
        else {
            //Message was received
        }
        
        cell.textLabel?.text = message.text
        
        return cell
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
