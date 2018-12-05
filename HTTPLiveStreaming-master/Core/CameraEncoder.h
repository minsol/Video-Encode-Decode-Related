//
//  CameraEncoder.h
//  HTTPLiveStreaming
//
//  Created by Byeong-uk Park on 2016. 2. 10..
//  Copyright © 2016년 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "H264HWEncoder.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "AACEncoder.h"
#endif

#if TARGET_OS_IPHONE
@interface CameraEncoder : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, H264HWEncoderDelegate, AACEncoderDelegate>
#else
@interface CameraEncoder : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, H264HWEncoderDelegate>
#endif

@property (weak, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

- (void) initCameraWithOutputSize:(CGSize)size;
- (void) startCamera;
- (void) stopCamera;

@end

