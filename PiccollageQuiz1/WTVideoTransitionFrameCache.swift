//
//  WTVideoTransitionFrameCache.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/27.
//

import Foundation
import AVFoundation
import GPUImage
import Photos

class WTVideoTransitionFrameCache: GPUImageOutput {
    
    var firstVideo:WTVideoReader
    var secondVideo:WTVideoReader
    var animatedTime: TimeInterval
    var movieWriter:GPUImageMovieWriter
    var filePath:URL
    
    var firstVideoCache:WTVideoFramCache?
    var secondVideoCache:WTVideoFramCache?
    var fx:WTTimeShiftFilter?
    var fx2:WTTimeShiftFilter?
    var bufferSize_f:Int = 0
    var bufferSize_s:Int = 0
    var startTime:CMTime = CMTime()
    var endTime:CMTime = CMTime()
    var isStartCombining:Bool = false
    
    var lastTimestamp: CMTime {
        get {
            guard let firstVideoCache = self.firstVideoCache else {
                return CMTime()
            }
            return firstVideoCache.timestampCache.last ?? CMTime()
        }
    }
    
    private lazy var blendingFilter:WTVideoAlphaBlendFilter = {
        let filter = WTVideoAlphaBlendFilter()
        filter.mix = 0.0
        filter.duration = Float(bufferSize_f + 1)
        return filter
    }()
    
    private lazy var irisBlendingFilter:WTVideoTransitionIris = {
        let filter = WTVideoTransitionIris(size: CGSize(width: 1280, height: 1920), duration: Float(bufferSize_f + 1))
        return filter!
    }()
    
    var currentProcessingVideo:WTVideoReader?
    
    init?(firstVideo:WTVideoReader, secondVideo:WTVideoReader, animatedTime: TimeInterval, movieWriter:GPUImageMovieWriter, filePath:URL) {
        self.firstVideo = firstVideo
        self.secondVideo = secondVideo
        self.animatedTime = animatedTime
        self.movieWriter = movieWriter
        self.filePath = filePath
        super.init()
        
        movieWriter.encodingLiveVideo = false
        movieWriter.shouldPassthroughAudio = false
        
        firstVideo.delegate = self
        secondVideo.delegate = self
        
        let orientationf = orientationForAsset(firstVideo.asset)
        fx = WTTimeShiftFilter()
        firstVideo.addTarget(fx)
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientationf) {
            self.fx!.setInputRotation(imageRotationMode, at: 0)
        }
        
        let orientations = orientationForAsset(secondVideo.asset)
        fx2 = WTTimeShiftFilter()
        secondVideo.addTarget(fx2)
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientations) {
            self.fx2!.setInputRotation(imageRotationMode, at: 0)
        }
        
        let track_f = self.firstVideo.asset.tracks(withMediaType: .video)
        guard let frameRate_f = track_f.first?.nominalFrameRate else { return }
        
        let track_s = self.secondVideo.asset.tracks(withMediaType: .video)
        guard let frameRate_s = track_s.first?.nominalFrameRate else { return }
        
        bufferSize_f = Int(frameRate_f) * Int(animatedTime)
        bufferSize_s = Int(frameRate_s) * Int(animatedTime)
        
        firstVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_f))
        secondVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_s))
        
        fx!.addTarget(firstVideoCache)
        fx2!.addTarget(secondVideoCache)
        
        currentProcessingVideo = firstVideo
        firstVideo.startProcessing()
        
        var sf = 0
        secondVideo.startProcessing { (timestamp) in
            if(sf >= self.bufferSize_s) {
                secondVideo.cancelProcessing()
            }
            sf = sf + 1
        }
        
    }
    
    override func addTarget(_ newTarget: GPUImageInput!) {
        blendingFilter.addTarget(newTarget)
    }
    
    override func addTarget(_ newTarget: GPUImageInput!, atTextureLocation textureLocation: Int) {
        blendingFilter.addTarget(newTarget, atTextureLocation: textureLocation)
    }
    
    func mixAndFlushFrame(completed: @escaping (()->())) {
        guard let firstVideoCache = self.firstVideoCache,
              let secondVideoCache = self.secondVideoCache else {
            return
        }
        let tempFilter = GPUImagePicture(image: UIImage(named: "bubble"))
        tempFilter!.addTarget(firstVideoCache)
        tempFilter!.addTarget(secondVideoCache)
        firstVideoCache.addTarget(irisBlendingFilter, atTextureLocation: 0)
        secondVideoCache.addTarget(irisBlendingFilter, atTextureLocation: 1)
        runAsynchronouslyOnVideoProcessingQueue {
            for _ in 0..<self.bufferSize_f {
                tempFilter?.processImage()
            }
            completed()
        }
    }
    
    func combine() {
        fx!.removeAllTargets()
        fx2!.removeAllTargets()
        fx2!.shiftTimestamp = CMTimeSubtract(firstVideoCache!.timestampCache.last!, secondVideoCache!.timestampCache.last!)
        fx!.addTarget(movieWriter)
        firstVideo = WTVideoReader(asset: firstVideo.asset)
        firstVideo.addTarget(fx)
        firstVideo.delegate = self
        currentProcessingVideo = firstVideo
        movieWriter.startRecording()
        firstVideo.startProcessing { (timestamp) in
            if(CMTimeCompare(timestamp, self.startTime) >= 0) {
                //self.movieWriter.isPaused = true
                self.firstVideo.cancelProcessing()
                self.fx!.removeAllTargets()
                self.irisBlendingFilter.addTarget(self.movieWriter)
                //self.movieWriter.isPaused = false
                self.mixAndFlushFrame {
                    //self.movieWriter.isPaused = true
                    self.firstVideoCache?.removeAllTargets()
                    self.secondVideoCache?.removeAllTargets()
                    self.irisBlendingFilter.removeAllTargets()
                    self.currentProcessingVideo = self.secondVideo
                    var hasAddWriter = false
                    self.secondVideo.startProcessing { (timestamp) in
                        if(CMTimeCompare(timestamp, self.endTime) >= 0 && !hasAddWriter) {
                            hasAddWriter = true
                            self.fx2!.addTarget(self.movieWriter)
                            //self.movieWriter.isPaused = false
                            
                        }
                    }
                }
            }
        }
    }
    
    func orientationForAsset(_ asset: AVAsset) -> UIInterfaceOrientation? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        let trackTransform = videoTrack.preferredTransform
        if trackTransform.a == -1 && trackTransform.d == -1 {
            return UIInterfaceOrientation.landscapeRight
        } else if trackTransform.a == 1 && trackTransform.d == 1  {
            return UIInterfaceOrientation.landscapeLeft
        } else if trackTransform.b == -1 && trackTransform.c == 1 {
            return UIInterfaceOrientation.portraitUpsideDown
        } else {
            return UIInterfaceOrientation.portrait
        }
    }
    
    func imageRotationMode(forUIInterfaceOrientation: UIInterfaceOrientation?) -> GPUImageRotationMode? {
        guard let forUIInterfaceOrientation = forUIInterfaceOrientation else {
            return nil
        }
        switch forUIInterfaceOrientation {
        case .landscapeRight:
            return GPUImageRotationMode.rotate180
        case .landscapeLeft:
            return GPUImageRotationMode.noRotation
        case .portrait:
            return GPUImageRotationMode.rotateRight
        case .portraitUpsideDown:
            return GPUImageRotationMode.rotateLeft
        default:
            return GPUImageRotationMode.noRotation
        }
    }
}

extension WTVideoTransitionFrameCache: GPUImageMovieDelegate
{
    func didCompletePlayingMovie() {
        if(isStartCombining) {
            if(currentProcessingVideo == secondVideo) {
                movieWriter.finishRecording {
                    DispatchQueue.main.async {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.filePath)
                        }) { saved, error in
                            if saved {
                                print("Done")
                            }
                        }
                    }
                }
            }
        } else {
            guard currentProcessingVideo != nil else {
                return
            }
            if(currentProcessingVideo == firstVideo) {
                startTime = firstVideoCache?.timestampCache.first ?? CMTime()
                currentProcessingVideo = secondVideo
            } else if(currentProcessingVideo == secondVideo) {
                endTime = secondVideoCache?.timestampCache.last ?? CMTime()
                isStartCombining = true
                combine()
            }
        }
    }
}
