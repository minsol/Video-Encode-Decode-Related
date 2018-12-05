//
//  RTSPClient.h
//  HTTPLiveStreaming
//
//  Created by Byeong-uk Park on 2016. 1. 26..
//  Copyright © 2016년 . All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

@class RTSPClient;

@protocol RTSPClientDelegate <NSObject>
- (void)onRTSPDidConnectedOK:(RTSPClient *)rtsp;
- (void)onRTSPDidConnectedFailed:(RTSPClient *)rtsp;
- (void)onRTSPDidDisConnected:(RTSPClient *)rtsp;
@optional
- (void)onRTSP:(RTSPClient *)rtsp didSETUPWithServerPort:(NSNumber *)server_port;
- (void)onRTSP:(RTSPClient *)rtsp didSETUP_AUDIOWithServerPort:(NSNumber *)server_port;
- (void)onRTSP:(RTSPClient *)rtsp didSETUP_VIDEOWithServerPort:(NSNumber *)server_port;
@end

@interface RTSPClient : NSObject

@property (weak, nonatomic) NSString *host; // ip address
@property (weak, nonatomic) NSString *address;
@property (nonatomic) NSInteger port;
@property (weak, nonatomic) NSString *instance;
@property (weak, nonatomic) NSString *streamName;
@property (weak, nonatomic) NSString *sessionid;
@property (weak, nonatomic) id<RTSPClientDelegate> delegate;

- (void)connect:(NSString *)address port:(NSInteger)port instance:(NSString *)instance stream:(NSString *)stream;
- (void)close;

@end
