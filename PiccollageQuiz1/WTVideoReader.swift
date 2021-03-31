//
//  WTVideoReader.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/31.
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
