//
//  MediaManager.swift
//  EditVideo
//
//  Created by 极目 on 2017/5/23.
//  Copyright © 2017年 极目. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos
import AVFoundation
import Foundation


class MediaManager: NSObject {
    
    static let sharedInstance = MediaManager()
    
    // MARK: -  音视频叠加、导出本地
    fileprivate var assetExport:AVAssetExportSession!//视频导出功能
    
    
    // MARK: -  视频帧读取方法一
    fileprivate var avAssetReader : AVAssetReader?
    fileprivate var videoTrackOutput : AVAssetReaderTrackOutput?
    fileprivate var audioTrackOutput  : AVAssetReaderTrackOutput?
    
    
    // MARK: -  视频帧读取方法二
    fileprivate var player:AVPlayer!
    fileprivate var videoOutput:AVPlayerItemVideoOutput!//视频输出流
    fileprivate var displayLink:CADisplayLink?//定时器
    fileprivate var newPixelBufferCallBack: ((Bool,CVPixelBuffer?,CMTime?) -> ())?//刷新时候的回调

    // MARK: -  添加滤镜后视频导出功能
    fileprivate var assetWriter: AVAssetWriter?
    fileprivate var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    fileprivate var audioInput: AVAssetWriterInput?
    var isWriting = false
    var currentVideoSize = CGRect()
    let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempVideo.mov")
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()
    

    private override init() {
        super.init()
    }
    
    
    
    // MARK: -  音视频叠加、导出本地
    func exportVideoToJMCollection(videoUrl:URL, audioUrl :URL,exportURL:URL,completionHandler: @escaping () -> Swift.Void) {

        let videoAsset = AVURLAsset(url: videoUrl)
        let audioAsset = AVURLAsset(url: audioUrl)

        let mixComposition = AVMutableComposition()
        
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        guard let clipVideoTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo).first else {
            return
        }
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: clipVideoTrack, at: kCMTimeZero)
        } catch {
            print("error")
        }
        compositionVideoTrack.preferredTransform = clipVideoTrack.preferredTransform

        
        //音频
        if let clipAudioTrack = audioAsset.tracks(withMediaType: AVMediaTypeAudio).first {
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: clipAudioTrack, at: kCMTimeZero)
            } catch {
                print("error")
            }
            compositionAudioTrack.preferredTransform = clipAudioTrack.preferredTransform
        }
        
        self.assetExport = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)

        
        if FileManager.default.fileExists(atPath: exportURL.path) {
            do { try FileManager.default.removeItem(atPath: exportURL.path)} catch{}
        }
        
        self.assetExport.outputFileType = AVFileTypeQuickTimeMovie
        self.assetExport.outputURL = exportURL
        self.assetExport.shouldOptimizeForNetworkUse = true
        self.assetExport.exportAsynchronously(completionHandler: completionHandler)
    }

    
    
    
    // MARK: -  AssetReader视频帧读取方法一
    func avAssetReaderGetCMSampleBuffer(url: URL,nextCMSampleBufferCallBack:@escaping (_ state:Bool,_ videoBuffer:CMSampleBuffer?,_ audioBuffer:CMSampleBuffer?) -> ()){
        let videoAsset = AVURLAsset(url: url)
        avAssetReader = try?AVAssetReader(asset: videoAsset)
        
        
        if let videoTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo).first {
            videoTrackOutput = AVAssetReaderTrackOutput.init(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
            avAssetReader?.add(videoTrackOutput!)
        }
        
        if let audioTrack = videoAsset.tracks(withMediaType: AVMediaTypeAudio).first {
            audioTrackOutput = AVAssetReaderTrackOutput.init(track: audioTrack, outputSettings:nil)
            avAssetReader?.add(audioTrackOutput!)
        }
        avAssetReader?.startReading()
        
        while avAssetReader?.status == .reading {
            //视频
            if let sampleBuffer = videoTrackOutput?.copyNextSampleBuffer(){
                //音频
                if let AudioBuffer = audioTrackOutput?.copyNextSampleBuffer(){
//                    print("CMSampleBufferGetPresentationTimeStamp(AudioBuffer):::::::::\(CMSampleBufferGetPresentationTimeStamp(AudioBuffer))")
                    nextCMSampleBufferCallBack(true, sampleBuffer, AudioBuffer)
                }else{
                    nextCMSampleBufferCallBack(true, sampleBuffer, nil)
                }
            }
        }
        nextCMSampleBufferCallBack(false, nil, nil)
    }
    
    
    
    // MARK: -  AVPlayer视频帧读取方法二,通过AVPlayer获取
    func avplayerGetNewPixelBuffer(url: URL,newPixelBufferCallBack:@escaping (Bool,CVPixelBuffer?,CMTime?) -> ()) {
        player = AVPlayer(url: url)
        self.newPixelBufferCallBack = newPixelBufferCallBack
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
        player.currentItem?.add(videoOutput)
        startDisplayLink()
        player.play()
    }
    
    @objc private func displayLinkDidRefresh(_ link: CADisplayLink) {
        //转成视频播放当前时间
        let itemTime = videoOutput.itemTime(forHostTime: CACurrentMediaTime())
        
        //判断播放是否完成
        let timescale  = Double((player.currentItem?.duration.timescale)!)
        let value = Double((player.currentItem?.duration.value)!)
        let totleTime = value/timescale
        
        let currentTime = Double(CMTimeGetSeconds(player.currentTime()))
        if currentTime == totleTime {
            releaseDisplayLink()
            player.pause()
            newPixelBufferCallBack!(false,nil,nil)
        }else{
            if videoOutput.hasNewPixelBuffer(forItemTime: itemTime) {
                var presentationItemTime = kCMTimeZero
                if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationItemTime){
                    currentVideoSize = CVImageBufferGetCleanRect(pixelBuffer)//输出视频的尺寸
                    newPixelBufferCallBack!(true,pixelBuffer,itemTime)
                }
            }
        }
    }
    
    private func startDisplayLink() {
        releaseDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh(_:)))
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    private func releaseDisplayLink() {
        print("释放::::::::")
        displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
        displayLink?.invalidate()
    }
    
    
    
    
    // MARK: -  添加滤镜后视频导出功能
    func writerVedioTolocal(readWrite:Bool,ciImage:CIImage?,itmeTimer:CMTime?,completionHandler: @escaping () -> Swift.Void) {
        
        if readWrite {
            if !self.isWriting {
                self.isWriting = true
                self.createWriter()
                self.assetWriter?.startWriting()
                self.assetWriter?.startSession(atSourceTime: itmeTimer!)
            }
            
            // 本地存储视频的处理
            if self.isWriting {
                if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                    var newPixelBuffer: CVPixelBuffer? = nil
                    CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                    self.context.render(ciImage!, to: newPixelBuffer!, bounds: (ciImage?.extent)!, colorSpace: nil)//这个没有就输出黑屏
                    let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: itmeTimer!)//拼接视频PixelBuffer
                    if success == false {
                        print("Pixel Buffer没有附加成功")
                    }
                }
            }
        }else{
            self.isWriting = false
            self.assetWriterPixelBufferInput = nil
            self.assetWriter?.finishWriting(completionHandler: completionHandler)
        }
    }

    private func createWriter() {
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
//          assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        
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
        
//        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil)
//        assetWriter?.add(audioInput!)
        
    }
    
    private func checkForAndDeleteFile() {
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
    
}
