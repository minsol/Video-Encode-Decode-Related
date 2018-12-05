//
//  AAPLPlayerViewController.h
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 5..
//  Copyright © 2016년 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AAPLPlayerView;

@interface AAPLPlayerViewController : UIViewController

@property (readonly) AVQueuePlayer *player;

@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;

@end

