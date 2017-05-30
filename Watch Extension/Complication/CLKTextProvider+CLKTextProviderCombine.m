//
//  CLKTextProvider+CLKTextProviderCombine.m
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

#import "CLKTextProvider+CLKTextProviderCombine.h"

@implementation CLKTextProvider (CLKTextProviderCombine)

+ (nonnull CLKTextProvider *)textProviderByJoiningProvider:(nonnull CLKTextProvider *)provider1 andProvider:(nonnull CLKTextProvider *)provider2 withString:(nullable NSString *)joinString
{
    NSString *textProviderToken = @"%@";
    
    NSString *formatString;
    
    if (joinString != nil) {
        formatString = [NSString stringWithFormat:@"%@%@%@",
                        textProviderToken,
                        joinString,
                        textProviderToken];
    }
    else {
        formatString = [NSString stringWithFormat:@"%@%@",
                        textProviderToken,
                        textProviderToken];
    }
    
    return [self textProviderWithFormat:formatString, provider1, provider2];
}
    
@end
