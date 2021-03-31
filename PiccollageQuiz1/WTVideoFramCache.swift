//
//  WTVideoFramCache.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/29.
//

import Foundation
import GPUImage

class WTVideoFramCache: GPUImageBuffer {
    
    var timestampCache:[CMTime] = [CMTime]()
    
    init(cacheSize:UInt) {
        super.init()
        bufferSize = cacheSize
    }
    
    override init!(fragmentShaderFrom fragmentShaderString: String!) {
        super.init(fragmentShaderFrom: fragmentShaderString)
    }
    
    override init!(vertexShaderFrom vertexShaderString: String!, fragmentShaderFrom fragmentShaderString: String!) {
        super.init(vertexShaderFrom: vertexShaderString, fragmentShaderFrom: fragmentShaderString)
    }
    
    override func newFrameReady(at frameTime: CMTime, at textureIndex: Int) {
        var frameTimeC = frameTime
        if(timestampCache.count >= bufferSize) {
            frameTimeC = timestampCache.first!
            timestampCache.removeFirst()
        } 
        timestampCache.append(frameTime)
        super.newFrameReady(at: frameTimeC, at: textureIndex)
    }
}

class WTTimeShiftFilter: GPUImageFilter {
    var shiftTimestamp:CMTime = CMTime.zero
    
    override func newFrameReady(at frameTime: CMTime, at textureIndex: Int) {
        super.newFrameReady(at: CMTimeAdd(frameTime, shiftTimestamp), at: textureIndex)
    }
}
