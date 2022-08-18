//
//  LoginButton.swift
//  TheMovieManager
//
//  Created by Perla Jimenez on 15/08/2022.
//

import UIKit

class LoginButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 5
        tintColor = UIColor.white
        backgroundColor = UIColor.primaryDark
    }
    
}
