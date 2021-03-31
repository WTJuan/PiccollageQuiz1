//
//  WTVideoYuli.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/31.
//

import Foundation

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
