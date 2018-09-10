//
//  Message.swift
//  LetsChat
//
//  Created by Zubair on 08/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import Foundation
import Firebase

class Message {
    var toUserId = ""
    var fromUserId = ""
    var text = ""
    var timeStamp = ""

    init(dictionary: [String:String]) {
        self.fromUserId = dictionary["fromUserId"]!
        self.toUserId = dictionary["toUserId"]!
        self.text = dictionary["text"]!
        self.timeStamp = dictionary["timestamp"]!
    }
    
    var chatPartnerId: String? {
        
        guard let loggedInUserId =  Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let chatPartnerId = fromUserId == loggedInUserId ? toUserId : fromUserId
        return chatPartnerId
    }
}
