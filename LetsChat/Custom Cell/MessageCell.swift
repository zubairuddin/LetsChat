//
//  MessageCell.swift
//  LetsChat
//
//  Created by Zubair on 03/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var viewBubble: UIView!
    @IBOutlet weak var imgSender: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    
    @IBOutlet var viewBubbleLeading: NSLayoutConstraint!
    @IBOutlet var viewBubbleTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var viewBubbleWidth: NSLayoutConstraint!
    
    @IBOutlet weak var lblMessageTrailing: NSLayoutConstraint!
    @IBOutlet weak var lblMessageLeading: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
