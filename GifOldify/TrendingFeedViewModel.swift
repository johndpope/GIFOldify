//
//  TrendingFeedViewModel.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AFNetworking

class TrendingFeedViewModel {
    
    private(set) lazy var trendingGifs: Observable<[Gif]> = self.fetchTrendingGifs()
    private(set) lazy var moreTrendingGifs: Observable<[Gif]> = self.fetchTrendingGifs()
    private let pagingParams: PagingParams
    var start: Bool = false
    
    init() {
        pagingParams = PagingParams()
    }
    
    private func fetchTrendingGifs() -> Observable<[Gif]> {
        return Observable
            .create { observer in
                if self.start { self.resetPagination() }
                NetworkManager.shared().get("gifs/trending?api_key=7cc07a1ed64e48bab974610f0c97e8a1&limit=\(self.pagingParams.limit)&offset=\(self.pagingParams.offset)", parameters: nil, progress: nil, success: { (task, response) in
                    if let response = response as? [String: Any],
                        let data = response["data"] as? [[String: Any]] {
                        self.setPagination(response: response)
                        let gifs = data.map({ gifData -> Gif in
                            return Gif(data: gifData)
                        })
                        observer.onNext(gifs)
                        observer.onCompleted()
                    }
                }) { (task, error) in
                    print(error.localizedDescription)
                    observer.onError(error)
                }
                return Disposables.create()
        }
    }
    
    private func resetPagination() {
        pagingParams.limit = 20
        pagingParams.offset = 0
    }
    
    private func setPagination(response: [String: Any]) {
        if let pagination = response["pagination"] as? [String: Any],
            let count = pagination["count"] as? Int,
            let offset = pagination["offset"] as? Int {
            pagingParams.offset = (count + offset)
        }
    }
}

