//
//  AACEncoder.h
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 8..
//  Copyright © 2016년 . All rights reserved.
//
//  AAC Software Encoder

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AACEncoderDelegate <NSObject>

@required
- (void)gotAACEncodedData:(NSData*)data timestamp:(CMTime)timestamp error:(NSError*)error;

@end

@interface AACEncoder : NSObject

@property (weak, nonatomic) id<AACEncoderDelegate> delegate;

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encode:(CMSampleBufferRef)sampleBuffer;

@end