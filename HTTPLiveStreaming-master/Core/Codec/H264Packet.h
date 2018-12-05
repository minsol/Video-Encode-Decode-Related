//
//  H264Packet.h
//  HTTPLiveStreaming
//
//  Created by Byeong-uk Park on 2016. 2. 25..
//  Copyright © 2016년 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface H264Packet : NSObject

@property (strong, nonatomic) NSMutableData *packet;

- (id)initWithCMSampleBuffer:(CMSampleBufferRef)sample;

- (void)packetizeAVC:(CMSampleBufferRef)sample;

@end
