//
//  ViewController.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/25.
//

import UIKit
import GPUImage

class ViewController: UIViewController {

    @IBOutlet weak var processButton: UIButton!
    @IBOutlet weak var effectButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var gpuImageView: GPUImageView!
    
    private var firstVideo:AVAsset?
    private var secondVideo:AVAsset?
    
    private var transitionEffect:WTVideoTransitionEffect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        effectButton.addTarget(self, action: #selector(effectButtonTapped(_:)), for: .touchUpInside)
        processButton.addTarget(self, action: #selector(processButtonTapped(_:)), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped(sender:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func selectDidTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func selectVideo(video:AVAsset?) {
        if(video != nil && firstVideo == nil) {
            firstVideo = video
        } else if(video != nil && secondVideo == nil) {
            secondVideo = video
        }
    }
    
    @objc func effectButtonTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: "Effect", message: nil, preferredStyle: .actionSheet)
        let dissolveAction = UIAlertAction(title: "Dissolve", style: .default) { (action) in
            if(self.firstVideo != nil && self.secondVideo != nil) {
                self.transitionEffect = WTVideoTransitionEffectFactory.createEffect(type: .Dissolve, firstVideo: self.firstVideo!, secondVideo: self.secondVideo!, animatedTime: 2.0)
                DispatchQueue.main.async {
                    sheet.dismiss(animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    sheet.dismiss(animated: true, completion: nil)
                    self.showError(message: "Select two video first")
                }
            }
        }
        let irisAction = UIAlertAction(title: "Iris", style: .default) { (action) in
            if(self.firstVideo != nil && self.secondVideo != nil) {
                self.transitionEffect = WTVideoTransitionEffectFactory.createEffect(type: .Iris, firstVideo: self.firstVideo!, secondVideo: self.secondVideo!, animatedTime: 2.0)
                DispatchQueue.main.async {
                    sheet.dismiss(animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    sheet.dismiss(animated: true, completion: nil)
                    self.showError(message: "Select two video first")
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            sheet.dismiss(animated: true, completion: nil)
        }
        
        sheet.addAction(dissolveAction)
        sheet.addAction(irisAction)
        sheet.addAction(cancel)
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    @objc func processButtonTapped(_ sender: UIButton) {
        if(self.firstVideo != nil && self.secondVideo != nil && self.transitionEffect != nil && self.transitionEffect!.ready) {
            var documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0]
            let fileName = "\(Int(Date().timeIntervalSince1970)).mov"
            print(fileName)
            documentsPath.append(fileName)
            let exportUrl = URL(fileURLWithPath: documentsPath)
            if(FileManager.default.fileExists(atPath: exportUrl.absoluteString)) {
                try? FileManager.default.removeItem(atPath: exportUrl.absoluteString )
            }
    
            if let movieWriter = GPUImageMovieWriter(movieURL: exportUrl, size: CGSize(width: 1080,height: 1920)) {
                movieWriter.encodingLiveVideo = false
                let editor = WTVideoEditor(firstVideo: firstVideo!, secondVideo: secondVideo!, movieWriter: movieWriter, filePath: exportUrl, transitionEffect: transitionEffect!, finish: {
                    self.transitionEffect = nil
                    DispatchQueue.main.async {
                        guard let player = GPUImageMovie(asset: AVAsset(url: exportUrl)) else {
                            return
                        }
                        player.addTarget(self.gpuImageView)
                        player.playAtActualSpeed = true
                        player.startProcessing()
                    }
                })
                editor.combine()
            }
        } else {
            DispatchQueue.main.async {
                self.showError(message: "No selected video or effect two video")
            }
        }
    }
    
    @objc func clearButtonTapped(sender:UIButton) {
        firstVideo = nil
        secondVideo = nil
        transitionEffect = nil
    }
    
    func showError(message:String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let videoURL = info[.mediaURL] as? URL else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        print("select video url:\(videoURL.absoluteURL)")
        self.selectVideo(video: AVAsset(url: videoURL))
        picker.dismiss(animated: true, completion: nil)
    }
}
