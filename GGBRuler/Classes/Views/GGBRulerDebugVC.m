//
//  GGBRulerDebugVC.m
//  GGBRuler
//
//  Created by Maxim Grigoriev on 12/06/2017.
//  Copyright © 2017 Maxim Grigoriev. All rights reserved.
//

#import "GGBRulerDebugVC.h"

#import "GGBMotionTracker.h"


@interface GGBRulerDebugVC() // <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) GGBMotionTracker *motionTracker;

@property (weak, nonatomic) IBOutlet UIButton *startMeasureButton;
@property (weak, nonatomic) IBOutlet UIButton *calibrateButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;


@property (weak, nonatomic) IBOutlet UILabel *velocityValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityAxisValuesLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceAxisValuesLabel;

@property (weak, nonatomic) IBOutlet UILabel *accelValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *accelAxisValuesLabel;

@property (weak, nonatomic) IBOutlet UILabel *gravityValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *gravityAxisValuesLabel;

@property (weak, nonatomic) IBOutlet UILabel *attitudeValuesLabel;

@property (nonatomic, strong) NSMutableData *responseData;


@end


@implementation GGBRulerDebugVC

- (GGBMotionTracker *)motionTracker {
    
    if (!_motionTracker) {
        _motionTracker = [GGBMotionTracker sharedTracker];
    }
    return _motionTracker;
    
}


#pragma mark - button actions

- (IBAction)startMeasureButtonPressed:(id)sender {
    [self.motionTracker trigger];
}


- (IBAction)calibrateButtonPressed:(id)sender {
    
    [self.motionTracker calibrate];
    
}

- (IBAction)sendButtonPressed:(id)sender {
    
    [self sendData];
    
}

- (void)sendData {
    
    NSLog(@"sendData");
    
    //    NSURL *requestURL = [NSURL URLWithString:@"http://maxbook.local/~grimax/srvcs/accel.php"];
    NSURL *requestURL = [NSURL URLWithString:@"http://192.168.84.29/~grimax/srvcs/accel.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postData = [self stringFromMotionArray:self.motionTracker.motionsArray];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (!connection) {
        NSLog(@"connection error");
    }
    
}

- (NSString *)stringFromMotionArray:(NSArray *)motionArray {
    
    NSMutableString *resultString = [NSMutableString string];
    
    [resultString appendString:@"userAcceleration.x\tuserAcceleration.y\tuserAcceleration.z\t"];
    [resultString appendString:@"gravity.x\tgravity.y\tgravity.z\t"];
    [resultString appendString:@"pitch\troll\tyaw\t"];
    [resultString appendString:@"m11\tm12\tm13\t"];
    [resultString appendString:@"m21\tm22\tm23\t"];
    [resultString appendString:@"m31\tm32\tm33\t\r\n"];
    
    for (CMDeviceMotion *motion in motionArray) {
        
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\t", motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z]];
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\t", motion.gravity.x, motion.gravity.y, motion.gravity.z]];
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\t", motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw]];
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\t", motion.attitude.rotationMatrix.m11, motion.attitude.rotationMatrix.m12, motion.attitude.rotationMatrix.m13]];
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\t", motion.attitude.rotationMatrix.m21, motion.attitude.rotationMatrix.m22, motion.attitude.rotationMatrix.m23]];
        [resultString appendString:[NSString stringWithFormat:@"%f\t%f\t%f\r\n", motion.attitude.rotationMatrix.m31, motion.attitude.rotationMatrix.m32, motion.attitude.rotationMatrix.m33]];
        
    }
    
    return resultString;
    
}


- (void)motionTrackerStateChanged {
    
    if (self.motionTracker.measuring) {
        self.sendButton.enabled = NO;
        [self.startMeasureButton setTitle:@"Stop Measure" forState:UIControlStateNormal];
    } else {
        self.sendButton.enabled = YES;
        [self.startMeasureButton setTitle:@"Start Measure" forState:UIControlStateNormal];
    }
    
}

- (void)motionTrackerCalibrating {
    
    if (self.motionTracker.calibrating) {
        
        self.calibrateButton.enabled = NO;
        self.startMeasureButton.enabled = NO;
        self.sendButton.enabled = NO;
        
    } else {
        
        self.calibrateButton.enabled = YES;
        self.startMeasureButton.enabled = YES;
        self.sendButton.enabled = YES;
        
    }
    
}

- (void)motionTrackerNewValues:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    
    NSData *velocityData = [userInfo objectForKey:@"velocity"];
    NSData *devicePointData = [userInfo objectForKey:@"devicePoint"];
    
    ThreeDVelocity velocity;
    [velocityData getBytes:&velocity length:velocityData.length];
    
    self.velocityValueLabel.text = [NSString stringWithFormat:@"%.2f", [self.motionTracker modulusOfVector:velocity]];
    self.velocityAxisValuesLabel.text = [NSString stringWithFormat:@"%.2fx %.2fy %.2fz", velocity.x, velocity.y, velocity.z];
    
    ThreeDPoint devicePoint;
    [devicePointData getBytes:&devicePoint length:devicePointData.length];
    
    self.distanceValueLabel.text = [NSString stringWithFormat:@"%.2f", [self.motionTracker modulusOfVector:devicePoint]];
    self.distanceAxisValuesLabel.text = [NSString stringWithFormat:@"%.2fx %.2fy %.2fz", devicePoint.x, devicePoint.y, devicePoint.z];
    
    CMDeviceMotion *motion = [userInfo objectForKey:@"motion"];
    
    GGB3DVector accel;
    accel.x = motion.userAcceleration.x;
    accel.y = motion.userAcceleration.y;
    accel.z = motion.userAcceleration.z;
    
    self.accelValueLabel.text = [NSString stringWithFormat:@"%.2f", [self.motionTracker modulusOfVector:accel]];
    self.accelAxisValuesLabel.text = [NSString stringWithFormat:@"%.2fx %.2fy %.2fz", accel.x, accel.y, accel.z];
    
    GGB3DVector gravity;
    gravity.x = motion.gravity.x;
    gravity.y = motion.gravity.y;
    gravity.z = motion.gravity.z;
    
    self.gravityValueLabel.text = [NSString stringWithFormat:@"%.2f", [self.motionTracker modulusOfVector:gravity]];
    self.gravityAxisValuesLabel.text = [NSString stringWithFormat:@"%.2fx %.2fy %.2fz", gravity.x, gravity.y, gravity.z];
    
    self.attitudeValuesLabel.text = [NSString stringWithFormat:@"%.2fpitch %.2froll %.2fyaw", motion.attitude.pitch, motion.attitude.roll, motion.attitude.yaw];
    
    
}


#pragma mark - view lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    
//    [nc addObserver:self
//           selector:@selector(motionTrackerStateChanged)
//               name:@"motionTrackerStateChanged"
//             object:self.motionTracker];
//    
//    [nc addObserver:self
//           selector:@selector(motionTrackerCalibrating)
//               name:@"motionTrackerCalibrating"
//             object:self.motionTracker];
//    
//        [nc addObserver:self
//           selector:@selector(motionTrackerNewValues:)
//               name:@"motionTrackerNewValues"
//             object:self.motionTracker];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connection did fail with error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
    
}

@end
