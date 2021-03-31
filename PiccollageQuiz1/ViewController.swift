//
//  ViewController.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/25.
//

import UIKit
import GPUImage

class ViewController: UIViewController {

    @IBOutlet weak var gpuImageView: GPUImageView!
    var movieWriter: GPUImageMovieWriter?
    var blendFilter: WTVideoAlphaBlendFilter?
    var transition:WTVideoTransitionFrameCache?
    var finishCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let firstVideo = WTVideoReader(asset: AVAsset(url: Bundle.main.url(forResource: "IMG_2174", withExtension: "mp4")!)),
              let secondVideo = WTVideoReader(asset: AVAsset(url: Bundle.main.url(forResource: "IMG_2175", withExtension: "mp4")!)) else
        {
            return
        }
        
        var documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0]
        let fileName = "\(Int(Date().timeIntervalSince1970)).mov"
        print(fileName)
        documentsPath.append(fileName)
        let exportUrl = URL(fileURLWithPath: documentsPath)
        if(FileManager.default.fileExists(atPath: exportUrl.absoluteString)) {
            try? FileManager.default.removeItem(atPath: exportUrl.absoluteString )
        }
//        var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
//        tempURL.appendPathComponent("output.mov")
        
        if let movieWriter = GPUImageMovieWriter(movieURL: exportUrl, size: CGSize(width: 1080,height: 1920)),
           let transition = WTVideoTransitionFrameCache(firstVideo: firstVideo, secondVideo: secondVideo, animatedTime: 2.0, movieWriter: movieWriter, filePath: exportUrl) {
            self.transition = transition
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

}

