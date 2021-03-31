////
////  WTVideoTransitionFrameCache.swift
////  PiccollageQuiz1
////
////  Created by WeiTing Ruan on 2021/3/27.
////
//
//import Foundation
//import AVFoundation
//import GPUImage
//import Photos
//
//class WTVideoTransitionFrameCache: NSObject {
//    
//    var firstVideo:WTVideoReader
//    var secondVideo:WTVideoReader
//    var animatedTime: TimeInterval
//    var movieWriter:GPUImageMovieWriter
//    var filePath:URL
//    
//    var firstVideoCache:WTVideoFramCache?
//    var secondVideoCache:WTVideoFramCache?
//    var fx:WTTimeShiftFilter?
//    var fx2:WTTimeShiftFilter?
//    var bufferSize_f:Int = 0
//    var bufferSize_s:Int = 0
//    var startTime:CMTime = CMTime()
//    var endTime:CMTime = CMTime()
//    var isStartCombining:Bool = false
//    
//    var lastTimestamp: CMTime {
//        get {
//            guard let firstVideoCache = self.firstVideoCache else {
//                return CMTime()
//            }
//            return firstVideoCache.timestampCache.last ?? CMTime()
//        }
//    }
//    
//    private lazy var blendingFilter:WTVideoAlphaBlendFilter = {
//        let filter = WTVideoAlphaBlendFilter()
//        filter.mix = 0.0
//        filter.duration = Float(bufferSize_f + 1)
//        return filter
//    }()
//    
//    private lazy var irisBlendingFilter:WTVideoTransitionIris = {
//        let filter = WTVideoTransitionIris(size: CGSize(width: 1280, height: 1920), duration: Float(bufferSize_f + 1))
//        return filter!
//    }()
//    
//    var currentProcessingVideo:WTVideoReader?
//    
//    init?(firstVideo:WTVideoReader, secondVideo:WTVideoReader, animatedTime: TimeInterval, movieWriter:GPUImageMovieWriter, filePath:URL) {
//        self.firstVideo = firstVideo
//        self.secondVideo = secondVideo
//        self.animatedTime = animatedTime
//        self.movieWriter = movieWriter
//        self.filePath = filePath
//        super.init()
//        
//        movieWriter.encodingLiveVideo = false
//        movieWriter.shouldPassthroughAudio = false
//        
//        firstVideo.delegate = self
//        secondVideo.delegate = self
//        
//        let orientationf = orientationForAsset(firstVideo.asset)
//        fx = WTTimeShiftFilter()
//        firstVideo.addTarget(fx)
//        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientationf) {
//            self.fx!.setInputRotation(imageRotationMode, at: 0)
//        }
//        
//        let orientations = orientationForAsset(secondVideo.asset)
//        fx2 = WTTimeShiftFilter()
//        secondVideo.addTarget(fx2)
//        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientations) {
//            self.fx2!.setInputRotation(imageRotationMode, at: 0)
//        }
//        
//        let track_f = self.firstVideo.asset.tracks(withMediaType: .video)
//        guard let frameRate_f = track_f.first?.nominalFrameRate else { return }
//        
//        let track_s = self.secondVideo.asset.tracks(withMediaType: .video)
//        guard let frameRate_s = track_s.first?.nominalFrameRate else { return }
//        
//        bufferSize_f = Int(frameRate_f) * Int(animatedTime)
//        bufferSize_s = Int(frameRate_s) * Int(animatedTime)
//        
//        firstVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_f))
//        secondVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_s))
//        
//        fx!.addTarget(firstVideoCache)
//        fx2!.addTarget(secondVideoCache)
//        
//        currentProcessingVideo = firstVideo
//        firstVideo.startProcessing()
//        
//        var sf = 0
//        secondVideo.startProcessing { (timestamp) in
//            if(sf >= self.bufferSize_s) {
//                secondVideo.cancelProcessing()
//            }
//            sf = sf + 1
//        }
//        
//    }
//    
//    func mixAndFlushFrame(completed: @escaping (()->())) {
//        guard let firstVideoCache = self.firstVideoCache,
//              let secondVideoCache = self.secondVideoCache else {
//            return
//        }
//        let tempFilter = GPUImagePicture(image: UIImage(named: "bubble"))
//        tempFilter!.addTarget(firstVideoCache)
//        tempFilter!.addTarget(secondVideoCache)
//        firstVideoCache.addTarget(irisBlendingFilter, atTextureLocation: 0)
//        secondVideoCache.addTarget(irisBlendingFilter, atTextureLocation: 1)
//        runAsynchronouslyOnVideoProcessingQueue {
//            for _ in 0..<self.bufferSize_f {
//                tempFilter?.processImage()
//            }
//            completed()
//        }
//    }
//    
//    
//    
//    
//}
//
//extension WTVideoTransitionFrameCache: GPUImageMovieDelegate
//{
//    
//}
