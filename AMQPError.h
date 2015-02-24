//
//  AMQPError.h
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 23/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "amqp.h"

typedef NS_ENUM(NSUInteger, AMQPErrorCode) {
    AMQPErrorCodeSockInitError = AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR,
    AMQPErrorCodeSockError = AMQP_STATUS_SOCKET_ERROR,
    AMQPErrorCodeServerError = -0x0500,
};

@interface AMQPError : NSError

+ (NSString *)domain;

+ (instancetype)errorWithCode:(AMQPErrorCode)code userInfo:(NSDictionary *)userInfo;

+ (instancetype)errorWithCode:(AMQPErrorCode)code reply_t:(amqp_rpc_reply_t)reply;

+ (instancetype)errorWithCode:(AMQPErrorCode)code format:(NSString *)format,... NS_FORMAT_FUNCTION(2,3);

@end
