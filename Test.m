//
//  Test.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 3/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDTTYLogger.h>

// Log levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#import "Test.h"

@implementation Test

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogVerbose(@"Verbose");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    }
    return self;
}


@end
