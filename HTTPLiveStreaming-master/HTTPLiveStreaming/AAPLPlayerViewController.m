//
//  AAPLPlayerViewController.m
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 5..
//  Copyright © 2016년 . All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import CoreMedia.CMTime;

#import "AAPLPlayerView.h"
#import "AAPLPlayerViewController.h"

@interface AAPLPlayerViewController ()
{
    AVQueuePlayer *_player;
    AVURLAsset *_asset;
    
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    id<NSObject> _timeObserverToken;
    AVPlayerItem *_playerItem;
}

@property (readonly) AVPlayerLayer *playerLayer;

// Formatter to provide formatted value for seconds displayed in `startTimeLabel` and `durationLabel`.
@property (readonly) NSDateComponentsFormatter *timeRemainingFormatter;

@property (weak) IBOutlet AAPLPlayerView *playerView;

@end

@implementation AAPLPlayerViewController

// MARK: - View Controller

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
 */
static int AAPLPlayerViewControllerKVOContext = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playerView.playerLayer.player = self.player;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*
     Update the UI when these player properties change.
     
     Use the context parameter to distinguish KVO for our particular observers and not
     those destined for a subclass that also happens to be observing these properties.
     */
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    
    // Use a weak self variable to avoid a retain cycle in the block.
    AAPLPlayerViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double timeElapsed = CMTimeGetSeconds(time);
        
//        weakSelf.timeSlider.value = timeElapsed;
//        weakSelf.startTimeLabel.text = [weakSelf createTimeString: timeElapsed];
    }];
    
    NSString *urlString = @"http://devimages.apple.com/iphone/samples/bipbop/gear4/prog_index.m3u8";
    NSURL *url = [NSURL URLWithString:urlString];
    [self asynchronouslyLoadFromURL:url];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_timeObserverToken) {
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }
    
    [self.player pause];
    
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem" context:&AAPLPlayerViewControllerKVOContext];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK: - Properties

// Will attempt load and test these asset keys before playing
+ (NSArray *)assetKeysRequiredToPlay {
    return @[@"playable", @"hasProtectedContent"];
}

- (AVQueuePlayer *)player {
    if (!_player) {
        _player = [[AVQueuePlayer alloc] init];
    }
    return _player;
}

- (CMTime)currentTime {
    return self.player.currentTime;
}

- (void)setCurrentTime:(CMTime)newCurrentTime {
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (CMTime)duration {
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

- (float)rate {
    return self.player.rate;
}

- (void)setRate:(float)newRate {
    self.player.rate = newRate;
}

- (AVPlayerLayer *)playerLayer {
    return self.playerView.playerLayer;
}

- (NSDateComponentsFormatter *)timeRemainingFormatter {
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    return formatter;
}

// MARK: - Asset Loading

/*
 Prepare an AVAsset for use on a background thread. When the minimum set
 of properties we require (`assetKeysRequiredToPlay`) are loaded then add
 the asset to the `assetTitlesAndThumbnails` dictionary. We'll use that
 dictionary to populate the "Add Item" button popover.
 */
- (void)asynchronouslyLoadFromURL:(NSURL *)url {
    
    AVURLAsset *urlasset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    /*
     Using AVAsset now runs the risk of blocking the current thread (the
     main UI thread) whilst I/O happens to populate the properties. It's
     prudent to defer our work until the properties we need have been loaded.
     */
    [urlasset loadValuesAsynchronouslyForKeys:AAPLPlayerViewController.assetKeysRequiredToPlay completionHandler:^{
        
        /*
         The asset invokes its completion handler on an arbitrary queue.
         To avoid multiple threads using our internal state at the same time
         we'll elect to use the main thread at all times, let's dispatch
         our handler to the main queue.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            /*
             This method is called when the `AVAsset` for our URL has
             completed the loading of the values of the specified array
             of keys.
             */
            
            /*
             Test whether the values of each of the keys we need have been
             successfully loaded.
             */
            for (NSString *key in self.class.assetKeysRequiredToPlay) {
                NSError *error = nil;
                if ([urlasset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    NSString *stringFormat = NSLocalizedString(@"error.asset_%@_key_%@_failed.description", @"Can't use this AVAsset because one of it's keys failed to load");
                    
                    NSString *message = [NSString localizedStringWithFormat:stringFormat, url.absoluteString, key];
                    
                    [self handleErrorWithMessage:message error:error];
                    
                    return;
                }
            }
            
            // We can't play this asset.
            if (!urlasset.playable || urlasset.hasProtectedContent) {
                NSString *stringFormat = NSLocalizedString(@"error.asset_%@_not_playable.description", @"Can't use this AVAsset because it isn't playable or has protected content");
                
                NSString *message = [NSString localizedStringWithFormat:stringFormat, url.absoluteString];
                
                [self handleErrorWithMessage:message error:nil];
                
                return;
            }
            
            AVAsset *asset = [AVAsset assetWithURL:url];
            AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
            [self.player insertItem:newPlayerItem afterItem:nil];
            
            self.currentTime = kCMTimeZero;
            [self.player play];
        });
    }];
}

// MARK: - IBActions

- (IBAction)playPauseButtonWasPressed:(UIButton *)sender {
    if (self.player.rate != 1.0) {
        // Not playing foward; so play.
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            // At end; so got back to beginning.
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
    } else {
        // Playing; so pause.
        [self.player pause];
    }
}

- (IBAction)rewindButtonWasPressed:(UIButton *)sender {
    self.rate = MAX(self.player.rate - 2.0, -2.0); // rewind no faster than -2.0
}

- (IBAction)fastForwardButtonWasPressed:(UIButton *)sender {
    self.rate = MIN(self.player.rate + 2.0, 2.0); // fast forward no faster than 2.0
}

- (IBAction)timeSliderDidChange:(UISlider *)sender {
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 1000);
}

- (void)presentModalPopoverAlertController:(UIAlertController *)alertController sender:(UIButton *)sender {
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    alertController.popoverPresentationController.sourceView = sender;
    alertController.popoverPresentationController.sourceRect = sender.bounds;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alertController animated:true completion:nil];
}

// MARK: - KV Observation

// Update our UI when player or player.currentItem changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context != &AAPLPlayerViewControllerKVOContext) {
        // KVO isn't for us.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"player.currentItem"]) {
        //
    }
    else if ([keyPath isEqualToString:@"player.currentItem.duration"]) {
        // Update timeSlider and enable/disable controls when duration > 0.0
        
        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double currentTime = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
//        
//        self.timeSlider.maximumValue = newDurationSeconds;
//        self.timeSlider.value = currentTime;
//        self.rewindButton.enabled = hasValidDuration;
//        self.playPauseButton.enabled = hasValidDuration;
//        self.fastForwardButton.enabled = hasValidDuration;
//        self.timeSlider.enabled = hasValidDuration;
//        self.startTimeLabel.enabled = hasValidDuration;
//        self.startTimeLabel.text = [self createTimeString:currentTime];
//        self.durationLabel.enabled = hasValidDuration;
//        self.durationLabel.text = [self createTimeString:newDurationSeconds];
    }
    else if ([keyPath isEqualToString:@"player.rate"]) {
        // Update playPauseButton image
        
        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
//        UIImage *buttonImage = (newRate == 1.0) ? [UIImage imageNamed:@"PauseButton"] : [UIImage imageNamed:@"PlayButton"];
//        [self.playPauseButton setImage:buttonImage forState:UIControlStateNormal];
        
    }
    else if ([keyPath isEqualToString:@"player.currentItem.status"]) {
        // Display an error if status becomes Failed
        
        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if (newStatus == AVPlayerItemStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error:self.player.currentItem.error];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// Trigger KVO for anyone observing our properties affected by player and player.currentItem
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.duration" ]];
    } else if ([key isEqualToString:@"currentTime"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.currentTime" ]];
    } else if ([key isEqualToString:@"rate"]) {
        return [NSSet setWithArray:@[ @"player.rate" ]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

// MARK: - Error Handling

- (void)handleErrorWithMessage:(NSString *)message error:(NSError *)error {
    NSLog(@"Error occurred with message: %@, error: %@.", message, error);
    
    NSString *alertTitle = NSLocalizedString(@"alert.error.title", @"Alert title for errors");
    NSString *defaultAlertMessage = NSLocalizedString(@"error.default.description", @"Default error message when no NSError provided");
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:alertTitle message:message ?: defaultAlertMessage  preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *alertActionTitle = NSLocalizedString(@"alert.error.actions.OK", @"OK on error alert");
    UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    [controller addAction:action];
    
    [self presentViewController:controller animated:YES completion:nil];
}

// MARK: Convenience

- (NSString *)createTimeString:(double)time {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.second = (NSInteger)fmax(0.0, time);
    
    return [self.timeRemainingFormatter stringFromDateComponents:components];
}


@end
