//
//  CameraEncoder.m
//  HTTPLiveStreaming
//
//  Created by Byeong-uk Park on 2016. 2. 10..
//  Copyright © 2016년 . All rights reserved.
//

#import "CameraEncoder.h"

#import "RTSPClient.h"
#import "RTPClient.h"

#if !TARGET_OS_IPHONE
#import <CoreAudio/CoreAudio.h>
#endif

#define WMS_DOMAIN      @"ec2-52-79-124-139.ap-northeast-2.compute.amazonaws.com"
#define WMS_MODULE      @"live"
#define WMS_RTSP_PORT   1935
#define WMS_STREAM      @"mpegts"
#define WMS_VIDEO_PORT  10000
#define WMS_AUDIO_PORT  10001

@interface CameraEncoder () <RTSPClientDelegate>
{
    H264HWEncoder *h264Encoder;
#if TARGET_OS_IPHONE
    AACEncoder *aacEncoder;
#endif
    AVCaptureSession *captureSession;
//    NSString *h264File;
//    NSString *aacFile;
//    NSFileHandle *fileH264Handle;
//    NSFileHandle *fileAACHandle;
    AVCaptureConnection* connectionVideo;
    AVCaptureConnection* connectionAudio;
    RTSPClient *rtsp;
    RTPClient *rtp_h264, *rtp_aac;
    BOOL isReadyVideo, isReadyAudio;
}
@end

@implementation CameraEncoder

- (void)initCameraWithOutputSize:(CGSize)size
{
    h264Encoder = [[H264HWEncoder alloc] init];
    [h264Encoder setOutputSize:size];
    h264Encoder.delegate = self;
    
#if TARGET_OS_IPHONE
    aacEncoder = [[AACEncoder alloc] init];
    aacEncoder.delegate = self;
#endif
    
    rtsp = [[RTSPClient alloc] init];
    rtsp.delegate = self;
    
    rtp_h264 = [[RTPClient alloc] init];
    rtp_aac = [[RTPClient alloc] init];
    
    isReadyAudio = NO;
    isReadyVideo = NO;
    
    [self initCamera];
}

- (void)dealloc {
#if TARGET_OS_IPHONE
    [h264Encoder invalidate];
#endif
    isReadyAudio = NO;
    isReadyVideo = NO;
}

#pragma mark - Camera Control

- (void) initCamera
{
    // make input device
    
    NSError *deviceError;
    
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *microphoneDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    AVCaptureDeviceInput *inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    AVCaptureDeviceInput *inputMicrophoneDevice = [AVCaptureDeviceInput deviceInputWithDevice:microphoneDevice error:&deviceError];
    
    // make output device
    
    AVCaptureVideoDataOutput *outputVideoDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
    
    outputVideoDevice.videoSettings = videoSettings;
    
    [outputVideoDevice setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
    AVCaptureAudioDataOutput *outputAudioDevice = [[AVCaptureAudioDataOutput alloc] init];
    
#if !TARGET_OS_IPHONE
    NSDictionary *audioSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC), AVSampleRateKey : @44100, AVEncoderBitRateKey : @64000, AVNumberOfChannelsKey : @1};
    outputAudioDevice.audioSettings = audioSettings;
#endif
    
    [outputAudioDevice setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
    // initialize capture session
    
    captureSession = [[AVCaptureSession alloc] init];
    
    [captureSession addInput:inputCameraDevice];
    [captureSession addInput:inputMicrophoneDevice];
    [captureSession addOutput:outputVideoDevice];
    [captureSession addOutput:outputAudioDevice];
    
    // begin configuration for the AVCaptureSession
    [captureSession beginConfiguration];
    
    // picture resolution
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];
    
    connectionVideo = [outputVideoDevice connectionWithMediaType:AVMediaTypeVideo];
    connectionAudio = [outputAudioDevice connectionWithMediaType:AVMediaTypeAudio];
    
#if TARGET_OS_IPHONE
    [self setRelativeVideoOrientation];
    
    NSNotificationCenter* notify = [NSNotificationCenter defaultCenter];
    
    [notify addObserver:self
               selector:@selector(statusBarOrientationDidChange:)
                   name:@"StatusBarOrientationDidChange"
                 object:nil];
#endif
    
    [captureSession commitConfiguration];
    
    // make preview layer and add so that camera's view is displayed on screen
    
    self.previewLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (void) startCamera
{
    [captureSession startRunning];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    // Drop file to raw 264 track
//    h264File = [documentsDirectory stringByAppendingPathComponent:@"test.h264"];
//    [fileManager removeItemAtPath:h264File error:nil];
//    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
//    
//    // Open the file using POSIX as this is anyway a test application
//    fileH264Handle = [NSFileHandle fileHandleForWritingAtPath:h264File];
//    
//    // Drop file to raw aac track
//    aacFile = [documentsDirectory stringByAppendingPathComponent:@"test.aac"];
//    [fileManager removeItemAtPath:aacFile error:nil];
//    [fileManager createFileAtPath:aacFile contents:nil attributes:nil];
//    
//    // Open the file using POSIX as this is anyway a test application
//    fileAACHandle = [NSFileHandle fileHandleForWritingAtPath:aacFile];
    
    [rtsp connect:WMS_DOMAIN port:WMS_RTSP_PORT instance:WMS_MODULE stream:WMS_STREAM];
    
    rtp_h264.address = WMS_DOMAIN;
    rtp_h264.port = WMS_VIDEO_PORT;
    
    rtp_aac.address = WMS_DOMAIN;
    rtp_aac.port = WMS_AUDIO_PORT;
}

- (void) stopCamera
{
    [h264Encoder invalidate];
    [captureSession stopRunning];
    [rtsp close];
    [rtp_h264 reset];
    [rtp_aac reset];
//    [fileH264Handle closeFile];
//    fileH264Handle = NULL;
//    [fileAACHandle closeFile];
//    fileAACHandle = NULL;
    
#if !TARGET_OS_IPHONE
    
#endif
}

/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;	// 11111111  	= syncword
    packet[1] = (char)0xF9;	// 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

#if TARGET_OS_IPHONE
- (void)statusBarOrientationDidChange:(NSNotification*)notification {
    [self setRelativeVideoOrientation];
}

- (void)setRelativeVideoOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            connectionVideo.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            connectionVideo.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            connectionVideo.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            connectionVideo.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}
#endif

-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    if(connection == connectionVideo)
    {
        [h264Encoder encode:sampleBuffer];
    }
    else if(connection == connectionAudio)
    {
#if TARGET_OS_IPHONE
        [aacEncoder encode:sampleBuffer];
#else
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length, totalLength;
        char *dataPointer;
        CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        NSData *rawAAC = [NSData dataWithBytes:dataPointer length:totalLength];
        NSData *adtsHeader = [self adtsDataForPacketLength:totalLength];
        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
        [fullData appendData:rawAAC];
        
//        [fileAACHandle writeData:fullData];
        
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if(isReadyVideo && isReadyAudio) [rtp_aac publish:fullData timestamp:timestamp payloadType:97];
#endif
    }
}

#pragma mark - RTSPClientDelegate

- (void)onRTSPDidConnectedOK:(RTSPClient *)_rtsp
{
}

- (void)onRTSPDidConnectedFailed:(RTSPClient *)_rtsp
{
    [rtsp close];
}

- (void)onRTSPDidDisConnected:(RTSPClient *)_rtsp
{
    [rtsp close];
}

- (void)onRTSP:(RTSPClient *)rtsp didSETUP_AUDIOWithServerPort:(NSNumber *)server_port
{
    rtp_aac.port = [server_port intValue];
    isReadyAudio = YES;
}

- (void)onRTSP:(RTSPClient *)rtsp didSETUP_VIDEOWithServerPort:(NSNumber *)server_port
{
    rtp_h264.port = [server_port intValue];
    isReadyVideo = YES;
}

#pragma mark -  H264HWEncoderDelegate declare

- (void)gotH264EncodedData:(NSData *)packet timestamp:(CMTime)timestamp
{
//    NSLog(@"gotH264EncodedData %d", (int)[packet length]);
//    
//    [fileH264Handle writeData:packet];
    
    if(isReadyVideo && isReadyAudio) [rtp_h264 publish:packet timestamp:timestamp payloadType:98];
}

#if TARGET_OS_IPHONE
#pragma mark - AACEncoderDelegate declare

- (void)gotAACEncodedData:(NSData*)data timestamp:(CMTime)timestamp error:(NSError*)error
{
//    NSLog(@"gotAACEncodedData %d", (int)[data length]);
//
//    if (fileAACHandle != NULL)
//    {
//        [fileAACHandle writeData:data];
//    }

    if(isReadyVideo && isReadyAudio) [rtp_aac publish:data timestamp:timestamp payloadType:97];
}
#endif


@end
