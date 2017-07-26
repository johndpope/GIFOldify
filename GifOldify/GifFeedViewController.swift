//
//  GifFeedViewController.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AFNetworking
import AVFoundation
import AVKit

class GifFeedViewController: UIViewController, PackedLayoutDelegate, UICollectionViewDelegate, UISearchBarDelegate {
    
    fileprivate var collectionView: UICollectionView
    fileprivate var gifs: Variable<[Gif]> = Variable([])
    private let disposeBag: DisposeBag
    private let trendingFeedViewModel: TrendingFeedViewModel
    private let searchGifsViewModel: SearchGifsViewModel
    private let searchButton: UIButton
    private let backButton: UIButton
    fileprivate lazy var searchBar: UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
    fileprivate var searchText: String = ""
    private var reloadPaths: [IndexPath] = []
    fileprivate var isScrolling: Bool = false
    private let cellColors: [UIColor] = [UIColor.backgroundBlue(), UIColor.backgroundRed(), UIColor.backgroundGreen(), UIColor.backgroundPurple(), UIColor.backgroundYellow()]
    
    init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: PackedLayout())
        disposeBag = DisposeBag()
        trendingFeedViewModel = TrendingFeedViewModel()
        searchGifsViewModel = SearchGifsViewModel()
        searchButton = UIButton(type: .custom)
        backButton = UIButton(type: .custom)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUI()
        setupBindings()
        getTrendingGifs()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Trending Gifs"
        guard reloadPaths.count > 0 else { return }
        collectionView.reloadItems(at: reloadPaths)
    }
    
    func createUI() {
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
        
        self.title = "Trending Gifs"
        searchButton.setImage(UIImage(named: "search"), for: .normal)
        searchButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let barButton = UIBarButtonItem(customView: searchButton)
        self.navigationItem.rightBarButtonItem = barButton
        
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        self.searchBar.tintColor = .blue
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Search For GIFS"
        
        view.backgroundColor = UIColor.black
        
        collectionView.register(GifCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .clear
        if let layout = collectionView.collectionViewLayout as? PackedLayout {
            layout.delegate = self
        }
        view.addSubview(collectionView)
        
        addConstraints()
    }
    
    func addConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
    }
    
    func setupBindings() {
        searchButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.navigationItem.titleView = strongSelf.searchBar
            strongSelf.searchBar.becomeFirstResponder()
            let barButton = UIBarButtonItem(customView: strongSelf.backButton)
            strongSelf.navigationItem.leftBarButtonItem = barButton
            strongSelf.gifs.value.removeAll()
        }).addDisposableTo(disposeBag)
        
        searchBar.rx.text
            .orEmpty
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] query in
                guard let strongSelf = self else { return }
                strongSelf.searchText = query
                strongSelf.gifs.value.removeAll()
                strongSelf.getSearchedGifs(start: true, query: query)
            })
            .addDisposableTo(disposeBag)
        
        backButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.navigationItem.titleView = nil
            strongSelf.view.endEditing(true)
            strongSelf.searchBar.text = ""
            strongSelf.searchText = ""
            strongSelf.gifs.value.removeAll()
            strongSelf.getTrendingGifs(start: true)
            strongSelf.navigationItem.leftBarButtonItem = nil
        }).addDisposableTo(disposeBag)
        
        gifs.asObservable()
            .bind(to: collectionView.rx.items(cellIdentifier: "cell", cellType: GifCollectionViewCell.self)) { [weak self] (row, gif, cell) in
                guard let strongSelf = self else { return }
                cell.backgroundColor = strongSelf.cellColors[row % strongSelf.cellColors.count]
                if !strongSelf.isScrolling {
                    cell.setGif(gif: gif)
                }
            }.addDisposableTo(disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let strongSelf = self else { return }
                let selectedGif = strongSelf.gifs.value[indexPath.row]
                let oldifyGifVC = OldifyGifViewController(gif: selectedGif)
                
                DispatchQueue.main.async {
                    strongSelf.title = ""
                    strongSelf.navigationController?.pushViewController(oldifyGifVC, animated: true)
                    strongSelf.reloadPaths = strongSelf.collectionView.visibleCells.map({ (cell) -> IndexPath in
                        let c = cell as! GifCollectionViewCell
                        c.setNil()
                        return strongSelf.collectionView.indexPath(for: c)!
                    })
                }
            }).addDisposableTo(disposeBag)
        
        collectionView.rx.setDelegate(self).addDisposableTo(disposeBag)
    }
    
    func getTrendingGifs(start: Bool = false) {
        trendingFeedViewModel.start = start
        trendingFeedViewModel.trendingGifs
            .subscribe(onNext: { [weak self] (gifs) in
                guard let strongSelf = self else { return }
                strongSelf.gifs.value.append(contentsOf: gifs)
                strongSelf.collectionView.collectionViewLayout.invalidateLayout()
            }).addDisposableTo(disposeBag)
    }
    
    func getSearchedGifs(start: Bool = false, query: String) {
        self.searchGifsViewModel.searchGifs(start: start, query: query)
            .subscribe(onNext: { [weak self] (gifs) in
                guard let strongSelf = self else { return }
                strongSelf.gifs.value.append(contentsOf: gifs)
                strongSelf.collectionView.collectionViewLayout.invalidateLayout()
            }).addDisposableTo(disposeBag)
    }
    
    func collectionView(collectionView: UICollectionView, heightForGifAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let gif = gifs.value[indexPath.item]
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRect(aspectRatio: CGSize(width: Int(view.frame.width/2), height: gif.height), insideRect: boundingRect)
        return rect.size.height
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GifCollectionViewCell else { return }
        cell.setNil()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

extension GifFeedViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if distance < 200 {
            guard searchText.isEmpty else {
                getSearchedGifs(query: searchText)
                return
            }
            getTrendingGifs()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if(self.isScrolling){
            if(!decelerate){
                self.isScrolling = false
                let indexPaths = collectionView.visibleCells.map({ cell -> IndexPath in
                    return collectionView.indexPath(for: cell)!
                })
                UIView.performWithoutAnimation {
                    collectionView.reloadItems(at: indexPaths)
                    collectionView.layoutIfNeeded()
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if(self.isScrolling){
            self.isScrolling = false
            let indexPaths = collectionView.visibleCells.map({ cell -> IndexPath in
                return collectionView.indexPath(for: cell)!
            })
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: indexPaths)
                collectionView.layoutIfNeeded()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
        self.isScrolling = true
    }
}

extension GifFeedViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let gif = gifs.value[indexPath.row]
        
        let oldifyGifVC = OldifyGifViewController(gif: gif)
        oldifyGifVC.preferredContentSize = CGSize(width: 0, height: gif.originalHeight)
        previewingContext.sourceRect = cell.frame
        return oldifyGifVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}


