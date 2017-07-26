//
//  Gif.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import Foundation

struct Gif {
    
    private(set) var url: String?
    private(set) var height: Int = 0
    private(set) var originalUrl: String?
    private(set) var originalHeight: Int = 0
    private(set) var stillImageUrl: String?
    
    init(data: [String: Any]) {
        url = parseForVideoUrl(data: data)
        height = parseForHeight(data: data)
        originalUrl = parseForOriginalVideoUrl(data: data)
        originalHeight = parseForOriginalHeight(data: data)
        stillImageUrl = parseForStillImageUrl(data: data)
    }
    
    private func getFixedWidthDict(data: [String: Any]) -> [String: Any]? {
        if let images = data["images"] as? [String: Any],
            let fixedHeightDict = images["fixed_width"] as? [String: Any] {
            return fixedHeightDict
        }
        return nil
    }
    
    private func parseForVideoUrl(data: [String: Any]) -> String? {
        if let fixedHeightDict = getFixedWidthDict(data: data),
            let mp4Url = fixedHeightDict["mp4"] as? String {
            return mp4Url
        }
        return nil
    }
    
    private func parseForHeight(data: [String: Any]) -> Int {
        if let fixedHeightDict = getFixedWidthDict(data: data),
            let height = fixedHeightDict["height"] as? String {
            return Int(height)!
        }
        return 0
    }
    
    private func getOriginalHeightDict(data: [String: Any]) -> [String: Any]? {
        if let images = data["images"] as? [String: Any],
            let originalHeightDict = images["original"] as? [String: Any] {
            return originalHeightDict
        }
        return nil
    }
    
    private func parseForOriginalVideoUrl(data: [String: Any]) -> String? {
        if let originalHeightDict = getOriginalHeightDict(data: data),
            let mp4Url = originalHeightDict["mp4"] as? String {
            return mp4Url
        }
        return nil
    }
    
    private func parseForOriginalHeight(data: [String: Any]) -> Int {
        if let originalHeightDict = getOriginalHeightDict(data: data),
            let height = originalHeightDict["height"] as? String {
            return Int(height)!
        }
        return 0
    }
    
    private func parseForStillImageUrl(data: [String: Any]) -> String? {
        if let images = data["images"] as? [String: Any],
            let fixedWidthStillDict = images["fixed_width_still"] as? [String: Any],
            let fixedImageUrl = fixedWidthStillDict["url"] as? String{
            return fixedImageUrl
        }
        return nil
    }
}

