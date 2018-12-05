//
//  ViewController.swift
//  EditVideo
//
//  Created by 极目 on 2017/5/23.
//  Copyright © 2017年 极目. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AssetsLibrary


class ViewController: UIViewController {
    
//    var coreImageView: CoreImageView?
    var videoSource: VideoSampleBufferSource?
    
    var previewLayer: CALayer!

    var filter: CIFilter!//滤镜

    let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempVideo.mov")
    
    
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()
    
    fileprivate var assetWriter: AVAssetWriter?
    fileprivate var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    fileprivate var audioInput: AVAssetWriterInput?
    var isWriting = false

    var currentVideoSize =  CGRect()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        previewLayer.anchorPoint = CGPoint.zero
        previewLayer.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.width*(9/16))
        self.view.layer.insertSublayer(previewLayer, at: 0)
        
        currentVideoSize = CGRect(x: 0, y: 0, width:self.view.frame.width , height: self.view.frame.width*(9/16))

        
//        let videoUrl = URL(fileURLWithPath:Bundle.main.path(forResource: "IMG_2464", ofType: "MOV")!)
//        let audioUrl = URL(fileURLWithPath:Bundle.main.path(forResource: "月半弯", ofType: "mp3")!)

//        mixVideoAudio(videoUrl: videoUrl, audioUrl: audioUrl, exportURL: exportURL)
        
//        let url = Bundle.main.url(forResource: "IMG_2471", withExtension: "mov")!
//        let url = URL(fileURLWithPath:Bundle.main.path(forResource: "IMG_2464", ofType: "MOV")!)
        let url = Bundle.main.url(forResource: "test", withExtension: "mp4")!
        getVideoBuffer(videoUrl: url,exportURL:exportURL)
    }
    

    /// 获取视频帧数据
    func getVideoBuffer(videoUrl:URL,exportURL:URL) {

        MediaManager.sharedInstance.avplayerGetNewPixelBuffer(url: videoUrl) { [unowned self] success ,buffer , itmeTimer in
            
            var outputImage:CIImage? = nil
            if success {
                //添加滤镜流程
                //CVPixelBuffer -> CIImage -> 添加滤镜 -> CIImage -> CGImage -> 渲染到CALayer上显示
                let inputImage = CIImage(cvPixelBuffer: buffer!)//CIImage
                self.filter = CIFilter(name: "CIPhotoEffectTransfer")
                self.filter.setValue(inputImage, forKey: kCIInputImageKey)
                
                outputImage =  self.filter.outputImage!  //CIImage
                let cgImage  = self.context.createCGImage(outputImage!, from: (outputImage?.extent)!)!//CGImage
                self.previewLayer.contents = cgImage//显示在view上
            }
            
            //写入
            MediaManager.sharedInstance.writerVedioTolocal(readWrite: success, ciImage: outputImage, itmeTimer: itmeTimer, completionHandler: {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
                    }, completionHandler: { (finish, error) in
                        print("finish:::::::::\(finish)")
                        print("error:::::::::\(error.debugDescription)")
                    })
            })
        }

    }
    
    
    
    
    
    
    /// 影视频混合
    func mixVideoAudio(videoUrl:URL,audioUrl:URL,exportURL:URL)  {
        MediaManager.sharedInstance.exportVideoToJMCollection(videoUrl: videoUrl, audioUrl: audioUrl,exportURL:exportURL, completionHandler: {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }, completionHandler: { (finish, error) in
                print("finish:::::::::\(finish)")
                print("error:::::::::\(error.debugDescription)")
            })
        })
    }
    
    
    



    
    
    
    func createWriter() {
        checkForAndDeleteFile()
        
        do {
            assetWriter = try AVAssetWriter(outputURL: exportURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            print("创建writer失败")
            print(error.localizedDescription)
            return
        }
        
        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : currentVideoSize.width ,
            AVVideoHeightKey : currentVideoSize.height
            ] as [String : Any]
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
//        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        
        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : currentVideoSize.width ,
            String(kCVPixelBufferHeightKey) : currentVideoSize.height ,
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
            ] as [String : Any]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
        
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
        assetWriter?.add(audioInput!)
        
    }
    

    func checkForAndDeleteFile() {
        let fm = FileManager.default

        let exist = fm.fileExists(atPath: exportURL.path)
        
        if exist {
            print("删除之前的临时文件")
            do {
                try fm.removeItem(at: exportURL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

