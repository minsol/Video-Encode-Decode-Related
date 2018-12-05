//
//  H264HWDecoder.h
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 5..
//  Copyright © 2016년 . All rights reserved.
//
//  http://stackoverflow.com/questions/29525000/how-to-use-videotoolbox-to-decompress-h-264-video-stream/

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol H264HWDecoderDelegate <NSObject>

- (void)displayDecodedFrame:(CVImageBufferRef)imageBuffer;

@end

@interface H264HWDecoder : NSObject

@property (weak, nonatomic) id<H264HWDecoderDelegate> delegate;

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize isIFrame:(int)isIFrame;

@end
