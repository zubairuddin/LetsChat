//
//  User.swift
//  LetsChat
//
//  Created by Zubair on 08/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import Foundation

class User {
    var name = ""
    var email = ""
    var profileImageUrl = ""
    var id = ""
    
    init(userDict: [String:String]) {
        self.name = userDict["name"]!
        self.email = userDict["email"]!
        self.profileImageUrl = userDict["profileImageUrl"]!
    }
}
