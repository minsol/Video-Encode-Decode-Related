//
//  ViewController.m
//  HLSforOSX
//
//  Created by Byeong-uk Park on 2016. 2. 9..
//  Copyright © 2016년 . All rights reserved.
//

#import "CameraViewController.h"
#import "CameraEncoder.h"

@interface CameraViewController ()
{
    CameraEncoder *encoder;
    bool startCalled;
}
@property (weak, nonatomic) IBOutlet NSButton *StartStopButton;
@property (weak, nonatomic) IBOutlet NSView *preview;
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    encoder = [[CameraEncoder alloc] init];
    
    [encoder initCameraWithOutputSize:CGSizeMake(640, 360)];
    startCalled = true;
    
    [self.preview setWantsLayer:YES];
    
    encoder.previewLayer.frame = self.preview.bounds;
    [self.preview.layer addSublayer:encoder.previewLayer];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

// Called when start/stop button is pressed
- (IBAction)OnStartStop:(id)sender {
    if (startCalled)
    {
        [encoder startCamera];
        startCalled = false;
        [_StartStopButton setTitle:@"Stop"];
    }
    else
    {
        [_StartStopButton setTitle:@"Start"];
        startCalled = true;
        [encoder stopCamera];
    }
}

@end
