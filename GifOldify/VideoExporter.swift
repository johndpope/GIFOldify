//
//  VideoExporter.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import RxSwift
import RxCocoa

class VideoExporter {
    
    private let disposeBag: DisposeBag = DisposeBag()
    var progress: Variable<Float> = Variable(0.0)
    var saveSuccessful = PublishSubject<Bool>()
    
    func export(item: AVPlayerItem) {
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        let sourceVideoTrack = item.asset.tracks(withMediaType: AVMediaTypeVideo).first!
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, item.duration), of: sourceVideoTrack, at: kCMTimeZero)
        } catch(_) {
            return
        }
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        var preset: String = AVAssetExportPreset640x480
        if compatiblePresets.contains(AVAssetExportPreset640x480) { preset = AVAssetExportPreset640x480 }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: preset),
            exportSession.supportedFileTypes.contains(AVFileTypeMPEG4) else {
                return
        }
        
        var tempFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp_video.mp4", isDirectory: false)
        tempFileUrl = URL(fileURLWithPath: tempFileUrl.path)
        
        exportSession.outputURL = tempFileUrl
        exportSession.outputFileType = AVFileTypeMPEG4
        exportSession.videoComposition = item.videoComposition
        exportSession.shouldOptimizeForNetworkUse = false
        let startTime = CMTimeMake(0, 1)
        let timeRange = CMTimeRangeMake(startTime, item.duration)
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFileUrl)
                }) { [weak self] saved, error in
                    guard let strongSelf = self else { return }
                    if saved {
                        _ = try? Data(contentsOf: tempFileUrl)
                        _ = try? FileManager.default.removeItem(at: tempFileUrl)
                        strongSelf.saveSuccessful.onNext(true)
                    } else if let _ = error {
                        _ = try? Data(contentsOf: tempFileUrl)
                        _ = try? FileManager.default.removeItem(at: tempFileUrl)
                        strongSelf.saveSuccessful.onNext(false)
                    }
                }
            }
        }
        updateProgressValue(exportSession: exportSession)
    }
    
    func deleteExistingFile(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        }
        catch _ as NSError {
            
        }
    }
    
    func updateProgressValue(exportSession: AVAssetExportSession) {
        _ = Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.progress.value = exportSession.progress
            })
            .addDisposableTo(disposeBag)
    }
}

