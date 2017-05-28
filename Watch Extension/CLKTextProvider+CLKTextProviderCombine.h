//
//  CLKTextProvider+CLKTextProviderCombine.h
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

#import <ClockKit/ClockKit.h>

@interface CLKTextProvider (CLKTextProviderCombine)
    
+ (nonnull CLKTextProvider *)textProviderByJoiningProvider:(nonnull CLKTextProvider *)provider1 andProvider:(nonnull CLKTextProvider *)provider2 withString:(nullable NSString *)joinString;

@end
