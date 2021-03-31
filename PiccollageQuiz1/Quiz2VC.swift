//
//  Quiz2VC.swift
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/27.
//

//varying highp vec2 textureCoordinate;
//uniform sampler2D inputImageTexture;
//uniform lowp float diff_x;
//uniform lowp float diff_y;
//void main(){
//    highp float r = texture2D(inputImageTexture, textureCoordinate).r;
//
//    lowp vec2 nextP = textureCoordinate - vec2(diff_x, diff_y);
//    lowp vec2 nextPP = textureCoordinate - vec2(2 * diff_x, 2 * diff_y);
//
//    highp float g = 0.0;
//    if(nextP.x >= 0.0 && nextP.y >= 00.0) {
//        g = texture2D(inputImageTexture, nextP).g;
//    } else if(nextP.x < 0.0 && nextP.y >= 0.0) {
//        g = texture2D(inputImageTexture, vec2(0.0,nextP.y)).g;
//    } else if(nextP.x >= 0.0 && nextP.y < 0.0) {
//        g = texture2D(inputImageTexture, vec2(nextP.x,0.0)).g;
//    }
//
//    highp float b = 0.0;
//    if(nextPP.x >= 0 && nextPP.y >= 0) {
//        b = texture2D(inputImageTexture, nextPP).b;
//    } else if(nextPP.x < 0 && nextPP.y >= 0) {
//        b = texture2D(inputImageTexture, vec2(0,nextPP.y)).b;
//    } else if(nextPP.x >= 0 && nextPP.y < 0) {
//        b = texture2D(inputImageTexture, vec2(nextPP.x,0)).b;
//    }
//    gl_FragColor = vec4(r,g,b, 1.0);
//}

import UIKit
import GPUImage
import Photos

class Quiz2VC: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var gpuImageView: GPUImageView!
    var rgbeffect:WTRGBEffectFilter?
    override func viewDidLoad() {
        let uiiimage = UIImage(named: "bubble")
        let gpuImagePic = GPUImagePicture(image: uiiimage)

        rgbeffect = WTRGBEffectFilter(diffx: 30, diffy: 30, imageSize: (gpuImagePic?.outputImageSize())!)
        gpuImagePic?.addTarget(rgbeffect!)
        rgbeffect!.addTarget(gpuImageView)
        gpuImagePic?.processImage()
        GPUImageContext.sharedImageProcessing()?.framebufferCache.purgeAllUnassignedFramebuffers()
    }
    
    @IBAction func selectDidTapped(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func processImage(_ controller: UIImagePickerController, image:UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        guard let gpuImagePic = GPUImagePicture(image: image) else {
            return
        }
        gpuImagePic.addTarget(rgbeffect)
        rgbeffect?.imageSize = gpuImagePic.outputImageSize()
        gpuImagePic.processImage()
        GPUImageContext.sharedImageProcessing()?.framebufferCache.purgeAllUnassignedFramebuffers()
    }
}

extension Quiz2VC: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return self.processImage(picker, image: nil)
        }
        self.processImage(picker, image: image)
    }
}

class WTRGBEffectFilter: GPUImageFilter {
    
    let kWTRGBEffectFragmentShader = "varying highp vec2 textureCoordinate;uniform sampler2D inputImageTexture;uniform lowp float diff_x;uniform lowp float diff_y;void main(){highp float r = texture2D(inputImageTexture, textureCoordinate).r;lowp vec2 nextP = textureCoordinate - vec2(diff_x, diff_y);lowp vec2 nextPP = textureCoordinate - vec2(2.0 * diff_x, 2.0 * diff_y);highp float g = 0.0;if(nextP.x >= 0.0 && nextP.y >= 0.0) {g = texture2D(inputImageTexture, nextP).g;} else if(nextP.x < 0.0 && nextP.y >= 0.0) {g = texture2D(inputImageTexture, vec2(0.0,nextP.y)).g;} else if(nextP.x >= 0.0 && nextP.y < 0.0) {g = texture2D(inputImageTexture, vec2(nextP.x,0.0)).g;}highp float b = 0.0;if(nextPP.x >= 0.0 && nextPP.y >= 0.0) {b = texture2D(inputImageTexture, nextPP).b;} else if(nextPP.x < 0.0 && nextPP.y >= 0.0) {b = texture2D(inputImageTexture, vec2(0.0,nextPP.y)).b;} else if(nextPP.x >= 0.0 && nextPP.y < 0.0) {b = texture2D(inputImageTexture, vec2(nextPP.x,0.0)).b;}gl_FragColor = vec4(r,g,b, 1.0);}"
    
    var diffx:Float = 0
    var diffy:Float = 0
    var imageSize:CGSize = .zero
    
    var uniform_diff_x: GLint = 0
    var uniform_diff_y: GLint = 0
    
    init(diffx:Float, diffy:Float, imageSize:CGSize) {
        self.diffx = diffx
        self.diffy = diffy
        self.imageSize = imageSize
        super.init(vertexShaderFrom: kGPUImageVertexShaderString, fragmentShaderFrom:kWTRGBEffectFragmentShader)
        
        guard let currentProgram = GPUImageContext.sharedImageProcessing()?.currentShaderProgram else {
            return
        }
        
        uniform_diff_x = GLint(currentProgram.uniformIndex("diff_x"))
        uniform_diff_y = GLint(currentProgram.uniformIndex("diff_y"))
        
        setFloat(GLfloat((diffx/Float(imageSize.width))), forUniform: uniform_diff_x, program: currentProgram)
        setFloat(GLfloat((diffy/Float(imageSize.height))), forUniform: uniform_diff_y, program: currentProgram)
        
    }
    
    override init(vertexShaderFrom: String, fragmentShaderFrom: String) {
        super.init(vertexShaderFrom: vertexShaderFrom, fragmentShaderFrom: fragmentShaderFrom)
    }
    
    
}
