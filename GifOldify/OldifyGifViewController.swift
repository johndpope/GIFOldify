//
//  OldifyGifViewController.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation
import Photos

class OldifyGifViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    
    private let disposeBag: DisposeBag
    private let collectionView: UICollectionView
    private var dataSource: Variable<[Gif]> = Variable([])
    private let gif: Gif
    var progressBar: UIProgressView
    
    init(gif: Gif) {
        disposeBag = DisposeBag()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        self.gif = gif
        progressBar = UIProgressView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        setupBindings()
        addGif()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func createUI() {
        self.title = "Oldify"
        
        view.backgroundColor = UIColor.black
        
        progressBar.progressTintColor = UIColor.blue
        progressBar.progressViewStyle = .default
        view.addSubview(progressBar)
        progressBar.isHidden = true
        
        collectionView.register(GifCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        
        addConstraints()
    }
    
    func addConstraints() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height + 44).isActive = true
        progressBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        collectionView.topAnchor.constraint(equalTo: progressBar.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func setupBindings() {
        dataSource.asObservable()
            .bind(to: collectionView.rx.items(cellIdentifier: "cell", cellType: GifCollectionViewCell.self)) { (row, gif, cell) in
                cell.setGif(gif: gif, canSave: true)
                cell.saveButton!.rx.tap.subscribe(onNext: { [weak self] in
                    guard let strongSelf = self else { return }
                    guard strongSelf.hasPhotosAccess() else {
                        PHPhotoLibrary.requestAuthorization({ status in
                            if status == .authorized {
                                cell.saveButton!.isEnabled = false
                                DispatchQueue.main.async {
                                    strongSelf.saveVideo(item: cell.item, completion: {
                                        cell.saveButton!.isEnabled = true
                                    })
                                }
                            } else {
                                DispatchQueue.main.async {
                                    strongSelf.alertToAllowPhotosAccess()
                                }
                            }
                        })
                        return
                    }
                    cell.saveButton!.isEnabled = false
                    strongSelf.saveVideo(item: cell.item, completion: {
                        cell.saveButton!.isEnabled = true
                    })
                }).addDisposableTo(cell.disposeBag)
            }.addDisposableTo(disposeBag)
        
        collectionView.rx.setDelegate(self).addDisposableTo(disposeBag)
        
    }
    
    func hasPhotosAccess() -> Bool {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            return false
        }
        return true
    }
    
    func alertToAllowPhotosAccess() {
        let photosUnavailableAlertController = UIAlertController (title: "Photo Library Unavailable", message: "Please check to see if device settings doesn't allow photo library access", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        photosUnavailableAlertController .addAction(settingsAction)
        photosUnavailableAlertController .addAction(cancelAction)
        self.present(photosUnavailableAlertController, animated: true, completion: nil)
    }
    
    func saveVideo(item: AVPlayerItem, completion: @escaping (() -> ())) {
        let exporter = VideoExporter()
        exporter.export(item: item)
        progressBar.isHidden = false
        
        setupExportBindings(exporter: exporter, completion: completion)
    }
    
    func setupExportBindings(exporter: VideoExporter, completion: @escaping (() -> ())) {
        var saveSuccessful: Bool = true
        
        exporter.progress.asObservable()
            .subscribeOn(MainScheduler.instance)
            .takeWhile({ [weak self] _ -> Bool in
                guard let strongSelf = self else { return false }
                guard saveSuccessful else {
                    strongSelf.hideProgressBar()
                    completion()
                    return false
                }
                guard strongSelf.progressBar.progress < 1.0 else {
                    strongSelf.hideProgressBar()
                    completion()
                    return false
                }
                return true
            })
            .subscribe(onNext: { [weak self] (progress) in
                guard let strongSelf = self else { return }
                strongSelf.progressBar.setProgress(progress, animated: true)
            }).addDisposableTo(disposeBag)
        
        exporter.saveSuccessful.subscribe(onNext: { [weak self] (didSave) in
            guard let strongSelf = self else { return }
            if didSave {
                DispatchQueue.main.async {
                    strongSelf.animateSavedMessageView(message: "Saved GIF!")
                }
            } else {
                saveSuccessful = false
                DispatchQueue.main.async {
                    strongSelf.animateSavedMessageView(message: "Could not save GIF!")
                }
            }
        }).addDisposableTo(disposeBag)
    }
    
    func hideProgressBar() {
        progressBar.isHidden = true
        progressBar.setProgress(0.0, animated: false)
    }
    
    func animateSavedMessageView(message: String) {
        let savedMessageView = PopupMessageView(message: message, frame: CGRect(x: 0, y: -50, width: view.frame.width, height: 50))
        collectionView.addSubview(savedMessageView)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
            savedMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        }) { (completed) in
            UIView.animate(withDuration: 0.5, delay: 2.0, animations: {
                savedMessageView.frame = CGRect(x: 0, y: -50, width: self.view.frame.width, height: 50)
            }) { (completed) in
                savedMessageView.removeFromSuperview()
            }
        }
    }
    
    func addGif() {
        self.dataSource.value.append(gif)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Int(view.frame.width), height: gif.originalHeight + 70)
    }
}

