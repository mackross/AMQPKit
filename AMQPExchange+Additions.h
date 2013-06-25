//
//  AMQPExchange+Additions.h
//  SMARTClassroom
//
//  Created by Pedro Gomes on 27/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "AMQPExchange.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class AMQPQueue;
@interface AMQPExchange(Additions)

- (void)publishMessage:(NSString *)body messageID:(NSString *)messageID usingRoutingKey:(NSString *)theRoutingKey;

- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
               payload:(NSString *)body
       usingRoutingKey:(NSString *)theRoutingKey;

- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
           payloadData:(NSData *)body
       usingRoutingKey:(NSString *)theRoutingKey;

- (void)rpcCall:(NSString *)method
      messageID:(NSString *)messageID
        payload:(NSString *)body
  correlationID:(NSString *)correlationID
  callbackQueue:(AMQPQueue *)callbackQueue;

@end
