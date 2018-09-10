//
//  Extensions.swift
//  LetsChat
//
//  Created by Zubair on 02/09/18.
//  Copyright © 2018 Avicenna. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(withTitle title: String, andMessage message:String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

//Declare imageCache outside of extension otherwise we will get a compiler error
let imageCache = NSCache<AnyObject, AnyObject>()
extension UIImageView {
    
    func loadImageWithCachingFromUrl(imageUrl: URL) {
        
        //Check if cached image is available
        if let cachedImage = imageCache.object(forKey: imageUrl as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //else download image
        URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, response, error) in
            if let imageData = data {
                //Assign image to custom cell image view
                
                if let downloadedImage = UIImage(data: imageData) {
                    imageCache.setObject(downloadedImage, forKey: imageUrl as AnyObject)
                    
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                    }
                    
                }
                
            }
        }).resume()
    }
}
