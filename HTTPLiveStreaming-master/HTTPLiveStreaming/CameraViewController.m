//
//  CameraViewController.m
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 7..
//  Copyright © 2016년 . All rights reserved.
//

#import "CameraViewController.h"
#import "CameraEncoder.h"

@interface CameraViewController ()
{
    CameraEncoder *encoder;
    bool startCalled;
}
@property (weak, nonatomic) IBOutlet UIButton *StartStopButton;
@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    encoder = [[CameraEncoder alloc] init];
    
    [encoder initCameraWithOutputSize:CGSizeMake(360, 640)];
    
    startCalled = true;
    
    encoder.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:encoder.previewLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// Called when start/stop button is pressed
- (IBAction)OnStartStop:(id)sender {
    if (startCalled)
    {
        encoder.previewLayer.hidden = NO;
        [encoder startCamera];
        startCalled = false;
        [_StartStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else
    {
        encoder.previewLayer.hidden = YES;
        [_StartStopButton setTitle:@"Start" forState:UIControlStateNormal];
        startCalled = true;
        [encoder stopCamera];
    }
}

@end
