//
//  AMQPPrivate.h
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 3/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMQPChannel.h"
#import "LAMQPConnection.h"
#import "AMQPConsumer.h"
#import "AMQPQueue.h"
#import "AMQPExchange.h"

@class AMQPConnection;
@interface AMQPChannel ()
@property (assign, readwrite) amqp_channel_t internalChannel;
- (NSError *)openChannel:(amqp_channel_t)channel onConnection:(AMQPConnection *)connection;
@end

@interface LAMQPConnection ()
@property (assign, readwrite) amqp_connection_state_t internalConnection;
- (void)checkLastOperation:(NSString *)context;
@end

@interface AMQPConsumer ()
@property (assign, readwrite) amqp_bytes_t internalConsumer;
@end

@interface AMQPQueue ()
@property (assign, readwrite) amqp_bytes_t internalQueue;
@end

@interface AMQPExchange ()
@property (assign, readonly) amqp_bytes_t internalExchange;
@end

@interface AMQPMaybe : NSObject
+ (instancetype)error:(NSError *)error;
+ (instancetype)value:(id)value;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSError *error;
@end

