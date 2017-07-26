//
//  PopupMessageView.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit

class PopupMessageView: UIView {
    
    private let messageLabel: UILabel
    private var message: String = ""
    
    override init(frame: CGRect) {
        messageLabel = UILabel(frame: .zero)
        super.init(frame: frame)
    }
    
    convenience init(message: String, frame: CGRect) {
        self.init(frame: frame)
        self.message = message
        
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI() {
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        
        messageLabel.backgroundColor = .clear
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        addSubview(messageLabel)
        
        addConstraints()
    }
    
    func addConstraints() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
}

