//
//  VideoSampleBufferSource.swift
//  EditVideo
//
//  Created by 极目 on 2017/5/23.
//  Copyright © 2017年 极目. All rights reserved.
//

import Foundation
import AVFoundation
import GLKit

let pixelBufferDict: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]


class VideoSampleBufferSource: NSObject {
    
    var displayLink: CADisplayLink?//定时器
    
    let videoOutput: AVPlayerItemVideoOutput//视频输出流
    
    let newPixelBufferCallBack: (Bool,CVPixelBuffer?,CMTime?) -> ()//回调
    
    let player: AVPlayer
    
    
    init?(url: URL, consumer callback: @escaping (Bool,CVPixelBuffer?,CMTime?) -> ()) {
        
        player = AVPlayer(url: url)
        newPixelBufferCallBack = callback
        
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
        player.currentItem?.add(videoOutput)
        
        super.init()
        start()
        player.play()
    }
    
    func start() {
        releaseDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(VideoSampleBufferSource.displayLinkDidRefresh(_:)))
        displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    func displayLinkDidRefresh(_ link: CADisplayLink) {
        
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
            newPixelBufferCallBack(false,nil,nil)
        }else{
            if videoOutput.hasNewPixelBuffer(forItemTime: itemTime) {
                var presentationItemTime = kCMTimeZero
                let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationItemTime)
//                print("pixelBuffer:::::::::\(pixelBuffer)")
//                print("videoOutput:::::::::\(videoOutput.description)")
                newPixelBufferCallBack(true,pixelBuffer!,itemTime)
            }
        }
    }
    
    
    func releaseDisplayLink() {
        print("释放::::::::")
        displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
        displayLink?.invalidate()
    }

}
