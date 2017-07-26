//
//  PackedLayout.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import UIKit

protocol PackedLayoutDelegate {
    func collectionView(collectionView: UICollectionView, heightForGifAtIndexPath indexPath: NSIndexPath , withWidth width:CGFloat) -> CGFloat
}

class PackedLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var gifHeight: CGFloat = 0.0
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! PackedLayoutAttributes
        copy.gifHeight = gifHeight
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let attributtes = object as? PackedLayoutAttributes {
            if( attributtes.gifHeight == gifHeight  ) {
                return super.isEqual(object)
            }
        }
        return false
    }
}

class PackedLayout: UICollectionViewLayout {
    
    var delegate: PackedLayoutDelegate!
    
    var numberOfColumns = 2
    var cellPadding: CGFloat = 3.0
    
    private var cache = [PackedLayoutAttributes]()
    
    private var contentHeight: CGFloat  = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - (insets.left + insets.right)
    }
    
    override class var layoutAttributesClass: AnyClass {
        return PackedLayoutAttributes.self
    }
    
    override func prepare() {
        cache = [PackedLayoutAttributes]()
        contentHeight = 0
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        
        var xOffset = [CGFloat]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth )
        }
        
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        
        for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
            
            let indexPath = IndexPath(item: item, section: 0)
            
            let width = columnWidth - cellPadding * 2
            let cellHeight = delegate.collectionView(collectionView: collectionView!, heightForGifAtIndexPath: indexPath as NSIndexPath, withWidth: width)
            let height = cellHeight + 2*cellPadding
            
            var shortestColumn = 0
            if let minYOffset = yOffset.min() {
                shortestColumn = yOffset.index(of: minYOffset) ?? 0
            }
            
            let frame = CGRect(x: xOffset[shortestColumn], y: yOffset[shortestColumn], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = PackedLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            
            yOffset[shortestColumn] = yOffset[shortestColumn] + height
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes  in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
}

