//
//  GGBRulerCore.h
//  GGBRuler
//
//  Created by Maxim Grigoriev on 12/06/2017.
//  Copyright © 2017 Maxim Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGBRulerCore : NSObject

+ (instancetype)sharedRulerCore;

- (void)calibrateAccel;


@end
