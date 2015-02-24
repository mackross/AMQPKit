//
//  AMQPPrivate.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 3/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQP+Private.h"

#import "AMQPChannel.h"

@implementation AMQPMaybe

+ (instancetype)error:(NSError *)error
{
    AMQPMaybe *maybe = [[AMQPMaybe alloc] init];
    maybe->_error = error;
    return maybe;
}

+ (instancetype)value:(id)value
{
    AMQPMaybe *maybe = [[AMQPMaybe alloc] init];
    maybe->_value = value;
    return maybe;
}

@end