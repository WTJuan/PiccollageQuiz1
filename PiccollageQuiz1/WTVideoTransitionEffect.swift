//
//  WTVideoTransitionEffect.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/26.
//

import Foundation

enum WTVideoTransitionEffectType {
    case Dissolve
    case Iris
}

protocol WTVideoTransitionEffect {
    var duration:Double { get set }
    var ready:Bool { get set }
    var firstVideoSkipTime:CMTime { get set }
    var firstVideoEndTime:CMTime { get set }
    var secondVideoSkipTime:CMTime { get set }
    func mixAndFlushFrame(completed: @escaping (()->()))
    func addTarget(target:GPUImageInput)
}

class WTVideoTransitionEffectDissolve: NSObject, WTVideoTransitionEffect {
    var ready: Bool = false
    
    var firstVideoSkipTime: CMTime = CMTime.zero
    var firstVideoEndTime: CMTime = CMTime.zero
    var secondVideoSkipTime: CMTime = CMTime.zero
    var duration: Double = 0
    
    private var bufferSize_f:Int = 0
    private var bufferSize_s:Int = 0
    
    private var frameSize_f:CGSize = CGSize.zero
    private var frameSize_s:CGSize = CGSize.zero
    
    private var firstVideoCache:WTVideoFramCache?
    private var secondVideoCache:WTVideoFramCache?
    
    private var currentVideoReaderIndex:Int = 0

    private lazy var effectFilter:WTVideoTransitionDissolveFilter = {
       return WTVideoTransitionDissolveFilter()
    }()
    
    init(firstVideo:AVAsset, secondVideo:AVAsset, animatedTime:TimeInterval) {
        super.init()
        
        self.duration = Double(animatedTime)
        
        let track_f = firstVideo.tracks(withMediaType: .video)
        guard let frameRate_f = track_f.first?.nominalFrameRate,
              let frameSize_f = track_f.first?.naturalSize else { return }
        
        self.frameSize_f = frameSize_f
        
        let track_s = secondVideo.tracks(withMediaType: .video)
        guard let frameRate_s = track_s.first?.nominalFrameRate,
              let frameSize_s = track_s.first?.naturalSize else { return }
        
        self.frameSize_s = frameSize_s
        
        bufferSize_f = Int(frameRate_f) * Int(animatedTime)
        bufferSize_s = Int(frameRate_s) * Int(animatedTime)
        
        firstVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_f))
        secondVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_s))
        
        let orientationf = orientationForAsset(firstVideo)
        if(orientationf == UIInterfaceOrientation.portrait || orientationf == UIInterfaceOrientation.portraitUpsideDown) {
            self.frameSize_f = CGSize(width: frameSize_f.height, height: frameSize_f.width)
        }
        let firstVideoRotateFilter = GPUImageFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientationf) {
            firstVideoRotateFilter.setInputRotation(imageRotationMode, at: 0)
        }

        let orientations = orientationForAsset(secondVideo)
        if(orientations == UIInterfaceOrientation.portrait || orientations == UIInterfaceOrientation.portraitUpsideDown) {
            self.frameSize_s = CGSize(width: frameSize_s.height, height: frameSize_s.width)
        }
        let secondVideoRotateFilter = GPUImageFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientations) {
            secondVideoRotateFilter.setInputRotation(imageRotationMode, at: 0)
        }
        
        guard let firstVideoReader = WTVideoReader(asset: firstVideo),
              let secondVideoReader = WTVideoReader(asset: secondVideo) else { return }
        
        firstVideoReader.addTarget(firstVideoRotateFilter)
        firstVideoRotateFilter.addTarget(firstVideoCache)
        
        secondVideoReader.addTarget(secondVideoRotateFilter)
        secondVideoRotateFilter.addTarget(secondVideoCache)
        
        firstVideoReader.delegate = self
        secondVideoReader.delegate = self
        
        firstVideoReader.startProcessing()
        
        var sf = 0
        secondVideoReader.startProcessing { (timestamp) in
            if(sf >= self.bufferSize_s) {
                secondVideoReader.cancelProcessing()
                self.ready = true
            }
            sf = sf + 1
        }
    }
    
    func mixAndFlushFrame(completed: @escaping (() -> ())) {
        guard let firstVideoCache = self.firstVideoCache,
              let secondVideoCache = self.secondVideoCache else {
            return
        }
        let tempFilter = GPUImagePicture(image: UIImage(named: "bubble"))
        tempFilter!.addTarget(firstVideoCache)
        tempFilter!.addTarget(secondVideoCache)
        firstVideoCache.addTarget(effectFilter, atTextureLocation: 0)
        secondVideoCache.addTarget(effectFilter, atTextureLocation: 1)
        runAsynchronouslyOnVideoProcessingQueue {
            for _ in 0..<self.bufferSize_f {
                tempFilter?.processImage()
            }
            secondVideoCache.removeAllTargets()
            secondVideoCache.removeAllTargets()
            self.effectFilter.removeAllTargets()
            completed()
        }
    }
    
    func addTarget(target: GPUImageInput) {
        effectFilter.addTarget(target)
    }
}

extension WTVideoTransitionEffectDissolve: GPUImageMovieDelegate
{
    func didCompletePlayingMovie() {
        if(currentVideoReaderIndex == 0) {
            currentVideoReaderIndex += 1
            firstVideoSkipTime = firstVideoCache!.timestampCache.first!
            firstVideoEndTime = firstVideoCache!.timestampCache.last!
        } else {
            secondVideoSkipTime = secondVideoCache!.timestampCache.last!
        }
    }
}

class WTVideoTransitionEffectIris: NSObject, WTVideoTransitionEffect {
    var ready: Bool = false
    var firstVideoSkipTime: CMTime = CMTime.zero
    var firstVideoEndTime: CMTime = CMTime.zero
    var secondVideoSkipTime: CMTime = CMTime.zero
    var duration: Double = 0
    
    private var bufferSize_f:Int = 0
    private var bufferSize_s:Int = 0
    
    private var frameSize_f:CGSize = CGSize.zero
    private var frameSize_s:CGSize = CGSize.zero
    
    private var firstVideoCache:WTVideoFramCache?
    private var secondVideoCache:WTVideoFramCache?
    
    private var currentVideoReaderIndex:Int = 0
    
    private lazy var effectFilter:WTVideoTransitionIrisFilter = {
        return WTVideoTransitionIrisFilter(size: frameSize_f, duration: Float(bufferSize_f))
    }()
    
    init(firstVideo:AVAsset, secondVideo:AVAsset, animatedTime:TimeInterval) {
        super.init()
        
        self.duration = Double(animatedTime)
        
        let track_f = firstVideo.tracks(withMediaType: .video)
        guard let frameRate_f = track_f.first?.nominalFrameRate,
              let frameSize_f = track_f.first?.naturalSize else { return }
        
        self.frameSize_f = frameSize_f
        
        let track_s = secondVideo.tracks(withMediaType: .video)
        guard let frameRate_s = track_s.first?.nominalFrameRate,
              let frameSize_s = track_s.first?.naturalSize else { return }
        
        self.frameSize_s = frameSize_s
        
        bufferSize_f = Int(frameRate_f) * Int(animatedTime)
        bufferSize_s = Int(frameRate_s) * Int(animatedTime)
        
        firstVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_f))
        secondVideoCache = WTVideoFramCache(cacheSize: UInt(bufferSize_s))
        
        let orientationf = orientationForAsset(firstVideo)
        if(orientationf == UIInterfaceOrientation.portrait || orientationf == UIInterfaceOrientation.portraitUpsideDown) {
            self.frameSize_f = CGSize(width: frameSize_f.height, height: frameSize_f.width)
        }
        let firstVideoRotateFilter = GPUImageFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientationf) {
            firstVideoRotateFilter.setInputRotation(imageRotationMode, at: 0)
        }

        let orientations = orientationForAsset(secondVideo)
        if(orientations == UIInterfaceOrientation.portrait || orientations == UIInterfaceOrientation.portraitUpsideDown) {
            self.frameSize_s = CGSize(width: frameSize_s.height, height: frameSize_s.width)
        }
        let secondVideoRotateFilter = GPUImageFilter()
        if let imageRotationMode = imageRotationMode(forUIInterfaceOrientation: orientations) {
            secondVideoRotateFilter.setInputRotation(imageRotationMode, at: 0)
        }
        
        guard let firstVideoReader = WTVideoReader(asset: firstVideo),
              let secondVideoReader = WTVideoReader(asset: secondVideo) else { return }
        
        firstVideoReader.addTarget(firstVideoRotateFilter)
        firstVideoRotateFilter.addTarget(firstVideoCache)
        
        secondVideoReader.addTarget(secondVideoRotateFilter)
        secondVideoRotateFilter.addTarget(secondVideoCache)
        
        firstVideoReader.delegate = self
        secondVideoReader.delegate = self
        
        firstVideoReader.startProcessing()
        var sf = 0
        secondVideoReader.startProcessing { [self] (timestamp) in
            if(sf >= self.bufferSize_s) {
                secondVideoReader.cancelProcessing()
                self.ready = true
            }
            sf = sf + 1
        }
    }
    
    func mixAndFlushFrame(completed: @escaping (() -> ())) {
        guard let firstVideoCache = self.firstVideoCache,
              let secondVideoCache = self.secondVideoCache else {
            return
        }
        let tempFilter = GPUImagePicture(image: UIImage(named: "bubble"))
        tempFilter!.addTarget(firstVideoCache)
        tempFilter!.addTarget(secondVideoCache)
        firstVideoCache.addTarget(effectFilter, atTextureLocation: 0)
        secondVideoCache.addTarget(effectFilter, atTextureLocation: 1)
        runAsynchronouslyOnVideoProcessingQueue {
            for _ in 0..<self.bufferSize_f {
                tempFilter?.processImage()
            }
            secondVideoCache.removeAllTargets()
            secondVideoCache.removeAllTargets()
            self.effectFilter.removeAllTargets()
            completed()
        }
    }
    
    func addTarget(target: GPUImageInput) {
        effectFilter.addTarget(target)
    }
}

extension WTVideoTransitionEffectIris: GPUImageMovieDelegate
{
    func didCompletePlayingMovie() {
        if(currentVideoReaderIndex == 0) {
            currentVideoReaderIndex += 1
            firstVideoSkipTime = firstVideoCache!.timestampCache.first!
            firstVideoEndTime = firstVideoCache!.timestampCache.last!
        } else {
            secondVideoSkipTime = secondVideoCache!.timestampCache.last!
        }
    }
}

class WTVideoTransitionEffectFactory {
    static func createEffect(type:WTVideoTransitionEffectType,
                             firstVideo:AVAsset,
                             secondVideo:AVAsset,
                             animatedTime:TimeInterval) -> WTVideoTransitionEffect {
        switch type {
        case .Dissolve:
            return WTVideoTransitionEffectDissolve(firstVideo: firstVideo, secondVideo: secondVideo, animatedTime: animatedTime)
        case .Iris:
            return WTVideoTransitionEffectIris(firstVideo: firstVideo, secondVideo: secondVideo, animatedTime: animatedTime)
        }
        
    }
}
