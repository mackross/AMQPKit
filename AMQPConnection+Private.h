//
//  AMQPConnection+Private.h
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 19/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQPConnection.h"
#import "AMQP+Private.h"
#import "AMQPNetworkThread.h"

#import "amqp.h"
@class AMQPError;
@interface AMQPConnection ()


// Legacy
@property (assign, readwrite) amqp_connection_state_t internalConnection;
- (void)checkLastOperation:(NSString *)context;

@property (assign, readwrite) amqp_socket_t *internalSocket;
@property (assign, readwrite) NSUInteger channelCount;
@property (nonatomic, readonly) AMQPNetworkThread *networkThread;
@property (nonatomic, readonly) dispatch_queue_t connectionQueue;

- (AMQPError *)lastRPCReplyError;

/* Blocking Calls */

// nil error if connection was successful

@end
