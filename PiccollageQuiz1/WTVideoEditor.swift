//
//  WTVideoEditor.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/25.
//

import Foundation
import GPUImage
import Photos

class WTVideoEditor: NSObject {
    
    private var firstVideoReader: WTVideoReader?
    private var secondVideoReader: WTVideoReader?
    private var firstVideoRotateFilter:GPUImageFilter?
    private var secondVideoTimeShift:WTTimeShiftFilter?
    private var transitionEffect:WTVideoTransitionEffect
    private var movieWriter:GPUImageMovieWriter
    private var filePath:URL
    private var currentReaderIndex:Int = 0
    private var finishCallback:(()->())?
    
    init(firstVideo:AVAsset, secondVideo:AVAsset, movieWriter:GPUImageMovieWriter, filePath:URL, transitionEffect:WTVideoTransitionEffect, finish: (()->())?)
    {
        self.filePath = filePath
        self.movieWriter = movieWriter
        self.transitionEffect = transitionEffect
        self.finishCallback = finish
        super.init()
        
        self.firstVideoReader = WTVideoReader(asset: firstVideo)
        self.secondVideoReader = WTVideoReader(asset: secondVideo)
        
        let orientationf = orientationForAsset(firstVideo)
        firstVideoRotateFilter = GPUImageFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientationf) {
            firstVideoRotateFilter!.setInputRotation(imageRotationMode, at: 0)
        }

        let orientations = orientationForAsset(secondVideo)
        secondVideoTimeShift = WTTimeShiftFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientations) {
            secondVideoTimeShift!.setInputRotation(imageRotationMode, at: 0)
        }
    }
    
    func combine() {
        secondVideoTimeShift!.shiftTimestamp = CMTimeSubtract(transitionEffect.firstVideoEndTime, transitionEffect.secondVideoSkipTime)
        firstVideoRotateFilter!.addTarget(movieWriter)
        firstVideoReader!.addTarget(firstVideoRotateFilter)
        firstVideoReader!.delegate = self
        secondVideoReader!.delegate = self
        movieWriter.startRecording()
        firstVideoReader!.startProcessing { (timestamp) in
            if(CMTimeCompare(timestamp, self.transitionEffect.firstVideoSkipTime) >= 0) {
                self.firstVideoReader!.cancelProcessing()
                self.firstVideoRotateFilter!.removeAllTargets()
                self.transitionEffect.addTarget(target: self.movieWriter)
                self.transitionEffect.mixAndFlushFrame {
                    self.currentReaderIndex = 1
                    var hasAddWriter = false
                    self.secondVideoReader!.startProcessing { (timestamp) in
                        if(CMTimeCompare(timestamp, self.transitionEffect.secondVideoSkipTime) >= 0 && !hasAddWriter) {
                            hasAddWriter = true
                            self.secondVideoTimeShift!.addTarget(self.movieWriter)
                        }
                    }
                }
            }
        }
    }
}

extension WTVideoEditor: GPUImageMovieDelegate {
    func didCompletePlayingMovie() {
        if(currentReaderIndex == 1) {
            movieWriter.finishRecording {
                DispatchQueue.main.async {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.filePath)
                    }) { saved, error in
                        if saved {
                            if(self.finishCallback != nil) {
                                self.finishCallback!()
                            }
                        }
                    }
                }
            }
        }
    }
}
