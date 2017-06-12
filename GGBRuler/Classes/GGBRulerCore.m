//
//  GGBRulerCore.m
//  GGBRuler
//
//  Created by Maxim Grigoriev on 12/06/2017.
//  Copyright © 2017 Maxim Grigoriev. All rights reserved.
//

#import "GGBRulerCore.h"

@implementation GGBRulerCore

+ (instancetype)sharedRulerCore {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedRulerCore = nil;
    
    dispatch_once(&pred, ^{
        _sharedRulerCore = [[self alloc] init];
    });
    
    return _sharedRulerCore;
    
}

- (void)calibrateAccel {
    
}


@end
