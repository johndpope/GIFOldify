//
//  GifPlayerItem.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit
import AVFoundation

protocol GifPlayerItemDelegate {
    func play()
}

class GifPlayerItem: AVPlayerItem {
    
    var delegate: GifPlayerItemDelegate?
    private let notificationCenter: NotificationCenter
    
    init(url: URL) {
        notificationCenter = NotificationCenter.default
        super.init(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: [])
        self.addObservers()
    }
    
    deinit {
        self.removeObservers()
    }
    
    func addObservers() {
        self.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)
        notificationCenter.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self, queue: .main) { _ in
            self.delegate?.play()
        }
    }
    
    func removeObservers() {
        self.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: nil)
        notificationCenter.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "playbackLikelyToKeepUp" {
            delegate?.play()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

