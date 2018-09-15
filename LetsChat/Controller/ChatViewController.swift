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
    
    //MARK:- Outlets
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
    
    //MARK:- View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.tblMessages.allowsSelection = false
        //Get the stored messages from Firebase DB
        getMessagesFromFirebase()
        
        //Adding notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Add keyboard dismiss gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }

    //MARK:- Actions
    @IBAction func sendMessage(_ sender: UIButton) {
        handleSendMessage(toUser: selectedUser!)
    }
    
    //MARK:- Local methods
    @objc func dismissKeyboard() {
        txtMessage.resignFirstResponder()
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
            self.txtMessage.text = ""
            
            //Scroll to last row

            
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
    
    func scrollToLastRow() {
        
        if arrMessages.count > 0 {
            UIView.animate(withDuration: 0.2) {
                let indexPath = IndexPath(row: self.arrMessages.count - 1, section: 0)
                self.tblMessages.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: false)
            }
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
                    
                    self.scrollToLastRow()

                }
            })
        }
    }
    
    //Keyboard handling method
    @objc func keyBoardWillChange(notification:NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                print(keyboardFrame)
                
                //Substract bottom insets of safe area to resolve the extra spacing issue above keyboard on iPhoneX
                var keyBoardHeight = keyboardFrame.height
                if #available(iOS 11.0, *) {
                    keyBoardHeight -= view.safeAreaInsets.bottom
                }

                let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
                
                viewTypeMessageBottom.constant = isKeyboardShowing ? keyBoardHeight : 0
                
                UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    //Scroll to last row of tableview
                    if isKeyboardShowing {
                        self.scrollToLastRow()
                    }
                })
            }
        }
    }
    func estimateFrameForText(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }

    
}

//MARK:- UITableView datasource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrMessages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        let message = arrMessages[indexPath.row]
        
        cell.viewBubble.layer.cornerRadius = 15
        cell.viewBubble.layer.masksToBounds = true
        
        cell.lblMessage.text = message.text

        cell.viewBubbleWidth.constant = estimateFrameForText(message.text).width + 32
        
        //Detect if the message was sent or received
        if message.fromUserId == Auth.auth().currentUser!.uid {
            //Message was sent
            cell.viewBubbleLeading.isActive = false
            cell.viewBubbleTrailing.isActive = true
            
            cell.viewBubble.backgroundColor = UIColor(red: 0, green: 149/255, blue: 255/255, alpha: 1)
            cell.lblMessage.textColor = .white
            
        }
        else {
            //Message was received
            cell.viewBubbleLeading.isActive = true
            cell.viewBubbleTrailing.isActive = false
            
            cell.viewBubble.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            cell.lblMessage.textColor = .black

        }
        
        return cell
    }
}

//MARK:- UITextField delegate methods
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSendMessage(toUser: selectedUser!)
        return true
    }
}
