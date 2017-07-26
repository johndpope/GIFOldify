//
//  GifCollectionViewCell.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class GifCollectionViewCell: UICollectionViewCell, GifPlayerItemDelegate {
    
    private let notificationCenter: NotificationCenter
    private var player: AVPlayer!
    private(set) var saveButton: UIButton?
    private var canSave: Bool = false
    private(set) var disposeBag: DisposeBag
    private(set) var item: GifPlayerItem!
    
    override init(frame: CGRect) {
        notificationCenter = NotificationCenter.default
        disposeBag = DisposeBag()
        super.init(frame: frame)
    }
    
    deinit {
        prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        item = nil
    }
    
    func setNil() {
        if player != nil {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        playerLayer.player = nil
        item = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setGif(gif: Gif, canSave: Bool = false) {
        let gifUrl: URL?
        if canSave {
            self.canSave = canSave
            guard let url = gif.originalUrl else { return }
            gifUrl = URL(string: url)
            addSaveButton()
        } else {
            guard let url = gif.url else { return }
            gifUrl = URL(string: url)
        }
        if let url = gifUrl {
            addPlayerLayer(url: url)
        }
    }
    
    private func addSaveButton() {
        saveButton = UIButton(frame: .zero)
        saveButton!.backgroundColor = .clear
        saveButton!.layer.borderColor = UIColor.white.cgColor
        saveButton!.layer.borderWidth = 1
        saveButton!.layer.cornerRadius = 5
        saveButton!.setTitle("Save To Camera Roll", for: .normal)
        saveButton!.setTitleColor(.white, for: .normal)
        saveButton!.titleLabel?.textAlignment = .center
        contentView.addSubview(saveButton!)
        
        addSaveButtonConstraints()
    }
    
    private func addSaveButtonConstraints() {
        saveButton!.translatesAutoresizingMaskIntoConstraints = false
        saveButton!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton!.widthAnchor.constraint(equalToConstant: contentView.frame.width - 40).isActive = true
        saveButton!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        saveButton!.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    private func addPlayerLayer(url: URL) {
        item = GifPlayerItem(url: url)
        item.delegate = self
        self.player = AVPlayer(playerItem: item)
        
        if canSave {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height - 70)
            
            let filter = CIFilter(name: "CIPhotoEffectMono")!
            let asset = player.currentItem!.asset
            let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                let source = request.sourceImage.clampingToExtent()
                filter.setValue(source, forKey: kCIInputImageKey)
                
                let output = filter.outputImage!.cropping(to: request.sourceImage.extent)
                
                request.finish(with: output, context: nil)
            })
            player.currentItem!.videoComposition = composition
            playerLayer.player = player
            playerLayer.videoGravity = AVLayerVideoGravityResize
            DispatchQueue.main.async {
                self.contentView.layer.addSublayer(playerLayer)
            }
        } else {
            playerLayer.player = player
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        }
    }
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    func play() {
        playFromBeginning()
    }
    
    private func playFromBeginning() {
        self.player.seek(to: kCMTimeZero)
        self.player.play()
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

