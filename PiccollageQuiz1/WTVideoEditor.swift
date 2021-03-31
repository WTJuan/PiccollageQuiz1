//
//  WTVideoEditor.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/25.
//

import Foundation
import GPUImage

class WTVideoReader: GPUImageMovie {
    
    var timestampHandler:((CMTime) -> ())?
    
    func startProcessing(timestampHandler: @escaping ((CMTime) -> ())) {
        self.timestampHandler = timestampHandler
        super.startProcessing()
    }
    
    override func processMovieFrame(_ movieSampleBuffer: CMSampleBuffer!) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(movieSampleBuffer)
        if let timestampHandler = self.timestampHandler {
            timestampHandler(timestamp)
        }
        super.processMovieFrame(movieSampleBuffer)
    }
    
}


class WTVideoAlphaBlendFilter: GPUImageAlphaBlendFilter {
    
    var duration:Float
    
    override init() {
        self.duration = 0.0
        super.init()
    }
    
    override init!(fragmentShaderFrom fragmentShaderString: String!) {
        self.duration = 0.0
        super.init(fragmentShaderFrom: fragmentShaderString)
    }
    
    override init!(vertexShaderFrom vertexShaderString: String!, fragmentShaderFrom fragmentShaderString: String!) {
        self.duration = 0.0
        super.init(vertexShaderFrom: vertexShaderString, fragmentShaderFrom: fragmentShaderString)
    }
    
    override func newFrameReady(at frameTime: CMTime, at textureIndex: Int) {
        if(mix < 1.0) {
            self.mix = self.mix + CGFloat((1 / duration))
            if self.mix > 1.0 {
                self.mix = 1.0
            }
        }
        super.newFrameReady(at: frameTime, at: textureIndex)
        
    }
    
    override func informTargetsAboutNewFrame(at frameTime: CMTime) {
        print("mix:\(self.mix), blending \(CMTimeGetSeconds(frameTime))")
        super.informTargetsAboutNewFrame(at: frameTime)
    }
}
