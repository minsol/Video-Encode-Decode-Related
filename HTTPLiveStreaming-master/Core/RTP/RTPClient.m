//
//  TSClient.mm
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 14..
//  Copyright © 2016년 . All rights reserved.
//
//  https://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol
//  http://stackoverflow.com/questions/17896008/can-ffmpeg-library-send-the-live-h264-ios-camera-stream-to-wowza-using-rtsp
//  https://github.com/goertzenator/lwip/blob/master/contrib-1.4.0/apps/rtp/rtp.c

#import "RTPClient.h"
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>

struct rtp_header {
    u_int16_t v:2; /* protocol version */
    u_int16_t p:1; /* padding flag */
    u_int16_t x:1; /* header extension flag */
    u_int16_t cc:4; /* CSRC count */
    u_int16_t m:1; /* marker bit */
    u_int16_t pt:7; /* payload type */
    u_int16_t seq:16; /* sequence number */
    u_int32_t ts; /* timestamp */
    u_int32_t ssrc; /* synchronization source */
};

@interface RTPClient()
{
    GCDAsyncUdpSocket *socket_rtp;
    
    uint16_t seqNum;
    
    dispatch_queue_t queue;
    
    uint32_t start_t;
}
@end

@implementation RTPClient

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        socket_rtp = [[GCDAsyncUdpSocket alloc] init];
        [socket_rtp setDelegateQueue:queue];
        self.address = nil;
        self.port = 554;
        seqNum = 0;
        start_t = 0;
    }
    return self;
}

- (void)dealloc {
    [self reset];
    [socket_rtp closeAfterSending];
}

- (void)reset
{
    start_t = 0;
    seqNum = 0;
}

#pragma mark - Publish

- (void)publish:(NSData *)data timestamp:(CMTime)timestamp payloadType:(NSInteger)payloadType
{
    int32_t t = ((float)timestamp.value / timestamp.timescale) * 1000;
    if(start_t == 0) start_t = t;
    
    struct rtp_header header;
    
    //fill the header array of byte with RTP header fields
    header.v = 2;
    header.p = 0;
    header.x = 0;
    header.cc = 0;
    header.m = 0;
    header.pt = payloadType;
    header.seq = seqNum;
    header.ts = t - start_t;
    header.ssrc = (u_int32_t)self.port;
    
    /* send RTP stream packet */
    NSMutableData *packet = [NSMutableData dataWithBytes:&header length:12];
    [packet appendData:data];
    
    [socket_rtp sendData:(NSData *)packet toHost:self.address port:self.port withTimeout:-1 tag:0];
    
    seqNum++;
}

@end
