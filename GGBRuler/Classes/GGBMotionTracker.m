//
//  GGBMotionTracker.m
//  GGBRuler
//
//  Created by Maxim Grigoriev on 12/06/2017.
//  Copyright © 2017 Maxim Grigoriev. All rights reserved.
//

#import "GGBMotionTracker.h"


#define UPDATE_INTERVAL 0.01 // 0.01 — min interval (100Hz rate)
#define CALIBRATION_LEVEL 12 //4 8

@interface GGBMotionTracker()

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSMutableArray *calX;
@property (nonatomic, strong) NSMutableArray *calY;
@property (nonatomic, strong) NSMutableArray *calZ;
@property (nonatomic) GGB3DVector calError;
@property (nonatomic) BOOL calCalc;
@property (nonatomic, strong) NSDictionary *calibrationValues;

@property (nonatomic) CMAcceleration deviceAcceleration;
@property (nonatomic) GGB3DPoint devicePoint;
@property (nonatomic) GGB3DVelocity deviceVelocity;

@end

@implementation GGBMotionTracker

@synthesize measuring = _measuring;
@synthesize calibrating = _calibrating;


+ (instancetype)sharedTracker {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedTracker = nil;
    dispatch_once(&pred, ^{
        _sharedTracker = [[self alloc] init];
    });
    return _sharedTracker;
    
}

- (CMMotionManager *)motionManager {
    
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
    
}

- (void)trigger {
    (self.measuring) ? [self stopMeasure] : [self startMeasure];
}

- (void)setMeasuring:(BOOL)measuring {
    
    if (_measuring != measuring) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"motionTrackerStateChanged"
                                                            object:self];
        _measuring = measuring;
        
    }
    
}

- (void)setCalibrating:(BOOL)calibrating {

    if (_calibrating != calibrating) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"motionTrackerCalibrating"
                                                            object:self];
        _calibrating = calibrating;

    }
    
}


- (void)calibrate {
    
    self.calibrating = YES;
    
    self.motionsArray = [NSMutableArray array];
    
    if (!self.calX) {
        self.calX = [NSMutableArray array];
        self.calY = [NSMutableArray array];
        self.calZ = [NSMutableArray array];
    }
    
    NSLog(@"calibrate button pressed");
    [NSThread sleepForTimeInterval:10];
    
    NSLog(@"start Calibrate");
    self.motionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        
        if (error) {
            
            NSLog(@"start calibrate error %@", error);
            [self.motionManager stopDeviceMotionUpdates];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.calibrating = NO;
            });
            
        } else {
            
            //            NSLog(@"accel x %.3f, y %.3f, z %.3f", motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
            //            NSLog(@"accel z %.3f", motion.userAcceleration.z);
            
            [self.motionsArray addObject:motion];
            
            [self.calX addObject:[NSNumber numberWithDouble:motion.userAcceleration.x]];
            [self.calY addObject:[NSNumber numberWithDouble:motion.userAcceleration.y]];
            [self.calZ addObject:[NSNumber numberWithDouble:motion.userAcceleration.z]];
            //            [self.calX addObject:[NSNumber numberWithDouble:motion.gravity.x]];
            //            [self.calY addObject:[NSNumber numberWithDouble:motion.gravity.y]];
            //            [self.calZ addObject:[NSNumber numberWithDouble:motion.gravity.z]];
            
            //            NSLog(@"count %lu", (long unsigned)self.calX.count);
            
            //            if (self.calX.count > 100) {
            //                NSLog(@"! 100 !");
            //                [self.motionManager stopDeviceMotionUpdates];
            
            [self calcCalibrationData];
            
            //            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //                NSLog(@"x %.2f, y %.2f, z %.2f", motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
                
            });
            
        }
        
    }];
    
}

- (void)calcCalibrationData {
    
    //    NSLog(@"X %@", [self calcNormalDistributionFrom:self.calX]);
    //    NSLog(@"Y %@", [self calcNormalDistributionFrom:self.calY]);
    //    NSLog(@"Z %@", [self calcNormalDistributionFrom:self.calZ]);
    
    //    [self andersonDarlingTestForNormalityFor:self.calZ];
    
    if (!self.calCalc && self.calibrating) {
        
        self.calCalc = YES;
        
        double precision = 0.00001; // ???
        
        int count = (int)self.calX.count;
        
        if (count > 30) {
            
            GGB3DVector calAvrg;
            //            GGB3DVector calAvrgPrev;
            
            for (int i = 0; i < count; i++) {
                calAvrg.x += [self.calX[i] doubleValue] / count;
                calAvrg.y += [self.calY[i] doubleValue] / count;
                calAvrg.z += [self.calZ[i] doubleValue] / count;
                //                calAvrgPrev.x += [self.calX[i] doubleValue];
                //                calAvrgPrev.y += [self.calY[i] doubleValue];
                //                calAvrgPrev.z += [self.calZ[i] doubleValue];
            }
            //            calAvrg.x /= count;
            //            calAvrg.y /= count;
            //            calAvrg.z /= count;
            //            calAvrgPrev.x -= [self.calX[count - 1] doubleValue];
            //            calAvrgPrev.y -= [self.calY[count - 1] doubleValue];
            //            calAvrgPrev.z -= [self.calZ[count - 1] doubleValue];
            //            calAvrgPrev.x /= count - 1;
            //            calAvrgPrev.y /= count - 1;
            //            calAvrgPrev.z /= count - 1;
            
            NSLog(@"count %d calAvrg %f %f %f", count, calAvrg.x, calAvrg.y, calAvrg.z);
            //            NSLog(@"count %d calAvrgPrev %f %f %f", count, calAvrgPrev.x, calAvrgPrev.y, calAvrgPrev.z);
            //            NSLog(@"count %d self.calError %f %f %f", count, self.calError.x, self.calError.y, self.calError.z);
            //            NSLog(@"count %d dif %f %f %f", count, fabs(calAvrg.x - calAvrgPrev.x), fabs(calAvrg.y - calAvrgPrev.y), fabs(calAvrg.z - calAvrgPrev.z));
            NSLog(@"count %d dif %f %f %f", count, fabs(calAvrg.x - self.calError.x), fabs(calAvrg.y - self.calError.y), fabs(calAvrg.z - self.calError.z));
            
            if (fabs(calAvrg.x - self.calError.x) < precision && fabs(calAvrg.y - self.calError.y) < precision && fabs(calAvrg.z - self.calError.z) < precision) {
                
                NSLog(@"count %d got precision!", count);
                [self.motionManager stopDeviceMotionUpdates];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.calibrating = NO;
                });
                
            }
            
            self.calError = calAvrg;
            
        }
        
        self.calCalc = NO;
        
    }
    
}


#pragma mark - checkMotionDataForNormality

- (void)checkMotionDataForNormality {
    
    NSMutableArray *data = @[].mutableCopy;
    
    for (CMDeviceMotion *motion in self.motionsArray) {
        [data addObject:@(motion.userAcceleration.z)];
    }
    
    [self andersonDarlingTestForNormalityFor:data];
    
}

- (void)andersonDarlingTestForNormalityFor:(NSArray <NSNumber *> *)data {

    // https://en.wikipedia.org/wiki/Anderson–Darling_test
    
    data = [data sortedArrayUsingSelector:@selector(compare:)];

    NSLog(@"data %@", data);
    
    NSDictionary *normalParameters = [self calcNormalDistributionParamsFrom:data];
    NSArray *normalizedData = normalParameters[@"normalizedData"];

    NSUInteger n = normalizedData.count;
    double aSquare = 0.0;
    
    for (NSUInteger i = 1; i <= n; i++) {

        double datum = [normalizedData[i-1] doubleValue];

        double cdf = [self gaussianCDFForValue:datum];
        
        aSquare += [self aSquareValueForCDFValue:cdf
                                               i:i
                                               n:n];

    }
    
    aSquare = - (n + (aSquare / n));
    NSLog(@"aSquare %f", aSquare);

//    double aSquare1 = aSquare * (1.0 + 4.0 / n - 25.0 / pow(n, 2));
//    double aSquare2 = aSquare * (1.0 + 0.75 / n - 2.25 / pow(n, 2));
//
//    NSLog(@"aSquare1 %f", aSquare1);
//    NSLog(@"aSquare2 %f", aSquare2);

    // let reject normality if aSquare > 0.5

    if (aSquare > 0.5) {
        NSLog(@"data is not normal");
    }

}

- (NSDictionary *)calcNormalDistributionParamsFrom:(NSArray <NSNumber *> *)data {
    
    NSUInteger count = data.count;
    
    NSNumber *sum = [data valueForKeyPath:@"@sum.self"];
    
    double mean = sum.doubleValue / count;
    
    double sd = 0.0;
    
    for (NSNumber *datum in data) {
        sd += pow(datum.doubleValue - mean, 2);
    }
    
    sd /= count - 1;
    sd = sqrt(sd);
    
    NSMutableArray *normalizedData = @[].mutableCopy;
    
    for (NSNumber *datum in data) {
        [normalizedData addObject:@((datum.doubleValue - mean) / sd)];
    }
    
    NSDictionary *result = @{@"mean": @(mean),
                             @"sd": @(sd),
                             @"normalizedData": normalizedData};
    
    NSLog(@"result %@", result);
    
    return result;
    
}

- (double)gaussianCDFForValue:(double)x {
    
    NSInteger signX = (x > 0) ? 1 : (x < 0) ? -1 : 0;

    double result = 0.5 * (1 + signX * sqrt(1 - exp(-2 * pow(x, 2) / M_PI)));
    
    return result;
    
}

- (double)aSquareValueForCDFValue:(double)cdf i:(NSUInteger)i n:(NSUInteger)n {
    
    double result;
    result = (2.0 * i - 1.0) * log(cdf) + (2.0 * (n - i) + 1.0) * log(1.0 - cdf);
    return result;
    
}


#pragma mark - measurements

- (void)startMeasure {
    
    NSLog(@"start Measure");
    [self resetDevicePoint];
    
    self.motionsArray = [NSMutableArray array];
    
    self.motionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL;
    self.measuring = YES;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        
        if (error) {
            
            NSLog(@"Start motion update error %@", error);
            
            [self.motionManager stopDeviceMotionUpdates];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.measuring = NO;
            });
            
        } else {
            
            [self motionInfo:motion];
            
//            [self calculateMotion:motion];
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
                [self.motionsArray addObject:motion];

                if (self.motionsArray.count == 100) {
                    
                    [self stopMeasure];
                    [self checkMotionDataForNormality];
                    
                }
                
                //                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                //                                          [NSNumber numberWithDouble:[self modulusOfVector:self.deviceVelocity]], @"velocity",
                //                                          [NSNumber numberWithDouble:[self modulusOfVector:self.devicePoint]], @"distance",
                //                                          motion, @"motion",
                //                                          nil];
                
//                GGB3DVelocity velocity = self.deviceVelocity;
//                GGB3DPoint devicePoint = self.devicePoint;
//                CMAcceleration acceleration = self.deviceAcceleration;
                
//                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                          [NSData dataWithBytes:&acceleration length:sizeof(acceleration)], @"acceleration",
//                                          [NSData dataWithBytes:&velocity length:sizeof(velocity)], @"velocity",
//                                          [NSData dataWithBytes:&devicePoint length:sizeof(devicePoint)], @"devicePoint",
//                                          motion, @"motion",
//                                          nil];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"motionTrackerNewValues"
//                                                                    object:self
//                                                                  userInfo:userInfo];
                
//                self.caller.xLabel.text = [NSString stringWithFormat:@"%.2f", motion.userAcceleration.x];
//                self.caller.yLabel.text = [NSString stringWithFormat:@"%.2f", motion.userAcceleration.y];
//                self.caller.zLabel.text = [NSString stringWithFormat:@"%.2f", motion.userAcceleration.z];
//                NSLog(@"x %.2f, y %.2f, z %.2f", motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
                
            });
            
        }
        
    }];
    
}

- (void)motionInfo:(CMDeviceMotion *)motion {
    
    int coeff = 100;
    
    double x = round(motion.userAcceleration.x * coeff) / coeff;
    double y = round(motion.userAcceleration.y * coeff) / coeff;
    double z = round(motion.userAcceleration.z * coeff) / coeff;
    
    x = (x != 0) ? x : 0;
    y = (y != 0) ? y : 0;
    z = (z != 0) ? z : 0;
    
    NSLog(@"accel   x %.3f,     y %.3f,     z %.3f", x, y, z);
//    NSLog(@"gravity x %.3f, y %.3f, z %.3f", motion.gravity.x, motion.gravity.y, motion.gravity.z);

}

- (void)calculateMotion:(CMDeviceMotion *)motion {
    
    NSLog(@"%@", motion);
    
    CMAcceleration acc;
    acc.x = motion.userAcceleration.x - self.calError.x;
    acc.y = motion.userAcceleration.y - self.calError.y;
    acc.z = motion.userAcceleration.z - self.calError.z;
    
    CMAcceleration accRef;
    CMRotationMatrix rot = motion.attitude.rotationMatrix;
    
    accRef.x = acc.x*rot.m11 + acc.y*rot.m12 + acc.z*rot.m13;
    accRef.y = acc.x*rot.m21 + acc.y*rot.m22 + acc.z*rot.m23;
    accRef.z = acc.x*rot.m31 + acc.y*rot.m32 + acc.z*rot.m33;
    
    self.deviceAcceleration = accRef;
    
    NSLog(@"accel x %.3f, y %.3f, z %.3f", motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
    NSLog(@"gravity x %.3f, y %.3f, z %.3f", motion.gravity.x, motion.gravity.y, motion.gravity.z);
    NSLog(@"motion.attitude %@", motion.attitude);

    NSLog(@"accel z %.3f", motion.userAcceleration.z);
    
    NSTimeInterval interval = self.motionManager.deviceMotionUpdateInterval;
    CGFloat gForce = 9.81;
    CGFloat k = interval * gForce;
    
    GGB3DVelocity currentVelocity = self.deviceVelocity;
    currentVelocity.x = accRef.x * k;
    currentVelocity.y = accRef.y * k;
    currentVelocity.z = accRef.z * k;
    
    self.deviceVelocity = currentVelocity;
    
    NSLog(@"veloc x %.3f, y %.3f, z %.3f", self.deviceVelocity.x, self.deviceVelocity.y, self.deviceVelocity.z);
    NSLog(@"veloc z %.3f", self.deviceVelocity.z);
    
    GGB3DPoint currentPoint = self.devicePoint;
    currentPoint.x += self.deviceVelocity.x * interval;
    currentPoint.y += self.deviceVelocity.y * interval;
    currentPoint.z += self.deviceVelocity.z * interval;
    
    self.devicePoint = currentPoint;
    
    //    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    //                              [NSNumber numberWithDouble:[self modulusOfVector:self.deviceVelocity]], @"velocity",
    //                              [NSNumber numberWithDouble:[self modulusOfVector:self.devicePoint]], @"distance",
    //                              nil];
    //
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"motionTrackerNewValues"
    //                                                        object:self
    //                                                      userInfo:userInfo];
    
    NSLog(@"point x %.3f, y %.3f, z %.3f", self.devicePoint.x, self.devicePoint.y, self.devicePoint.z);
    NSLog(@"point z %.3f", self.devicePoint.z);
    
}

- (double)modulusOfVector:(GGB3DVector)vector {
    
    return sqrt(pow(vector.x, 2) + pow(vector.y, 2) + pow(vector.z, 2));
    
}

- (void)stopMeasure {
    
    [self.motionManager stopDeviceMotionUpdates];
    NSLog(@"stop Measure");
    self.measuring = NO;
    
}

- (void)resetDevicePoint {
    
    GGB3DPoint devicePoint;
    devicePoint.x = 0;
    devicePoint.y = 0;
    devicePoint.z = 0;
    self.devicePoint = devicePoint;
    
    GGB3DVelocity deviceVelocity;
    deviceVelocity.x = 0;
    deviceVelocity.y = 0;
    deviceVelocity.z = 0;
    self.deviceVelocity = deviceVelocity;
    
}


@end
