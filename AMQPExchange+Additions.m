//
//  AMQPExchange+Additions.m
//  SMARTClassroom
//
//  Created by Pedro Gomes on 27/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "AMQPExchange+Additions.h"
#import "AMQPChannel.h"

#import "amqp.h"
#import "amqp_framing.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation AMQPExchange(Additions)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
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
        ._flags     = AMQP_BASIC_MESSAGE_ID_FLAG | AMQP_BASIC_TYPE_FLAG,
        .type       = amqp_cstring_bytes([messageType UTF8String]),
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
@end
