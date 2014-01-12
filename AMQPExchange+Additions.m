//
//  AMQPExchange+Additions.m
//  Objective-C wrapper for librabbitmq-c
//
//  Created by Pedro Gomes on 27/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "AMQPExchange+Additions.h"
#import "AMQPChannel.h"
#import "AMQPQueue.h"

#import "amqp.h"
#import "amqp_framing.h"

@implementation AMQPExchange(Additions)

- (void)publishMessage:(NSString *)body messageID:(NSString *)messageID usingRoutingKey:(NSString *)theRoutingKey
{
    const amqp_basic_properties_t properties = (amqp_basic_properties_t){
        .message_id = amqp_cstring_bytes([messageID UTF8String]),
    };
	amqp_basic_publish(channel.connection.internalConnection,
                       channel.internalChannel,
                       exchange,
                       amqp_cstring_bytes([theRoutingKey UTF8String]),
                       NO,
                       NO,
                       &properties,
                       amqp_cstring_bytes([body UTF8String]));
	
	[channel.connection checkLastOperation:@"Failed to publish message"];
}

////////////////////////////////////////////////////////////////////////////////
// TODO: we need to add support for appID -- we can use this for versioning
////////////////////////////////////////////////////////////////////////////////
- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
               payload:(NSString *)body
       usingRoutingKey:(NSString *)theRoutingKey
{
    const amqp_basic_properties_t properties = (amqp_basic_properties_t) {
        ._flags     = AMQP_BASIC_MESSAGE_ID_FLAG | AMQP_BASIC_TYPE_FLAG | AMQP_BASIC_CONTENT_TYPE_FLAG,
        .type       = amqp_cstring_bytes([messageType UTF8String]),
        .message_id = amqp_cstring_bytes([messageID UTF8String]),
        .content_type = amqp_cstring_bytes([@"t" UTF8String]),
    };
	amqp_basic_publish(channel.connection.internalConnection,
                       channel.internalChannel,
                       exchange,
                       amqp_cstring_bytes([theRoutingKey UTF8String]),
                       NO,
                       NO,
                       &properties,
                       amqp_cstring_bytes([body UTF8String]));
	
	[channel.connection checkLastOperation:@"Failed to publish message"];
}

- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
           payloadData:(NSData *)body
       usingRoutingKey:(NSString *)theRoutingKey
{
    if (body.length == 0) {
        NSLog(@"payload is empty!!!");
        return;
    }
    const amqp_basic_properties_t properties = (amqp_basic_properties_t) {
        ._flags     = AMQP_BASIC_MESSAGE_ID_FLAG | AMQP_BASIC_TYPE_FLAG | AMQP_BASIC_CONTENT_TYPE_FLAG,
        .type       = amqp_cstring_bytes([messageType UTF8String]),
        .message_id = amqp_cstring_bytes([messageID UTF8String]),
        .content_type = amqp_cstring_bytes([@"b" UTF8String]),
    };

    amqp_bytes_t amqp_bytes = amqp_bytes_malloc(body.length);
    [body getBytes:amqp_bytes.bytes];
    
	amqp_basic_publish(channel.connection.internalConnection,
                       channel.internalChannel,
                       exchange,
                       amqp_cstring_bytes([theRoutingKey UTF8String]),
                       NO,
                       NO,
                       &properties,
                       amqp_bytes);

	amqp_bytes_free(amqp_bytes);
	[channel.connection checkLastOperation:@"Failed to publish message"];
    
}

- (void)publishMessage:(NSString *)messageType
             messageID:(NSString *)messageID
           payloadData:(NSData *)body
       usingRoutingKey:(NSString *)routingKey
         correlationID:(NSString *)correlationID
         callbackQueue:(NSString *)callbackQueue
{
    amqp_basic_properties_t properties = (amqp_basic_properties_t) {
        ._flags     = (AMQP_BASIC_MESSAGE_ID_FLAG       |
                       AMQP_BASIC_TYPE_FLAG             |
                       AMQP_BASIC_CONTENT_TYPE_FLAG     |
                       AMQP_BASIC_CORRELATION_ID_FLAG),
        .type       = amqp_cstring_bytes([messageType UTF8String]),
        .message_id = amqp_cstring_bytes([messageID UTF8String]),
        .content_type = amqp_cstring_bytes([@"b" UTF8String]),
        .correlation_id = amqp_cstring_bytes([correlationID UTF8String]),
    };
    
    if (callbackQueue) {
        properties._flags |= AMQP_BASIC_REPLY_TO_FLAG;
        properties.reply_to = amqp_cstring_bytes([callbackQueue UTF8String]);
    }
    
    amqp_bytes_t amqp_body = amqp_bytes_malloc(body.length);
    [body getBytes:amqp_body.bytes];
    
    amqp_basic_publish(channel.connection.internalConnection,
                       channel.internalChannel,
                       exchange,
                       amqp_cstring_bytes([routingKey UTF8String]),
                       NO,
                       NO,
                       &properties,
                       amqp_body);
    
    amqp_bytes_free(amqp_body);
    [channel.connection checkLastOperation:@"RPC call Invocation failed."];
}

@end
