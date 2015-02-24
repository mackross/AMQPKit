//
//  AMQPError.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 23/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQPError.h"
#import "AMQPErrorDecoder.h"

@implementation AMQPError

+ (NSString *)domain
{
    return @"com.amqpkit.error";
}

+ (instancetype)errorWithCode:(AMQPErrorCode)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:[self domain] code:code userInfo:userInfo];
}

+ (instancetype)errorWithCode:(AMQPErrorCode)code reply_t:(amqp_rpc_reply_t)reply
{
    NSString *errorDescription = [AMQPErrorDecoder errorDescriptionForReply:reply];
    NSDictionary *userInfo = (errorDescription ? @{ NSLocalizedDescriptionKey: errorDescription } : nil);
    return [self errorWithCode:code userInfo:userInfo];
}

+ (instancetype)errorWithCode:(AMQPErrorCode)code format:(NSString *)format, ...
{
    va_list va;
    va_start(va, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:va];
    va_end(va);
    
    NSDictionary *userInfo = (string ? @{ NSLocalizedDescriptionKey: string } : nil);
    return [self errorWithCode:code userInfo:userInfo];
}

@end
