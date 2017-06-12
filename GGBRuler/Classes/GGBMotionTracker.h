//
//  GGBMotionTracker.h
//  GGBRuler
//
//  Created by Maxim Grigoriev on 12/06/2017.
//  Copyright © 2017 Maxim Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreMotion/CoreMotion.h>


@interface GGBMotionTracker : NSObject

typedef struct GGB3DVector {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} GGB3DVector;

typedef GGB3DVector ThreeDPoint;
typedef GGB3DVector ThreeDVelocity;



+ (instancetype)sharedTracker;


- (double)modulusOfVector:(GGB3DVector)vector;
- (void)calibrate;
- (void)trigger;


@property (nonatomic, strong) NSMutableArray *motionsArray;

@property (nonatomic) BOOL measuring;
@property (nonatomic) BOOL calibrating;


@end
