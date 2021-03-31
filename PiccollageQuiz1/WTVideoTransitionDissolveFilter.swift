//
//  WTVideoTransitionDissolve.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/31.
//

import Foundation
import GPUImage

class WTVideoTransitionDissolveFilter: GPUImageAlphaBlendFilter {
    
    var duration:Float
    
    init(duration:Float) {
        self.duration = duration
        super.init()
    }
    
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
