//
//  AMQPConsumer.m
//  Objective-C wrapper for librabbitmq-c
//
//  Copyright 2009 Max Wolter. All rights reserved.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "AMQPConsumer.h"

//#import <string.h>
//#import <stdlib.h>

#import "AMQP+Private.h"
#import "AMQPQueue.h"
#import "AMQPMessage.h"
#import "AMQPConnection+Private.h"

#define ERROR_NO_MEMORY 1
#define ERROR_BAD_AMQP_DATA 2
#define ERROR_UNKNOWN_CLASS 3
#define ERROR_UNKNOWN_METHOD 4
#define ERROR_GETHOSTBYNAME_FAILED 5
#define ERROR_INCOMPATIBLE_AMQP_VERSION 6
#define ERROR_CONNECTION_CLOSED 7
#define ERROR_BAD_AMQP_URL 8
#define ERROR_MAX 8

@interface AMQPConsumer ()

@property (strong, readwrite) AMQPChannel *channel;
@property (strong, readwrite) AMQPQueue *queue;

@end

@implementation AMQPConsumer

- (id)initForQueue:(AMQPQueue *)theQueue onChannel:(AMQPChannel *)theChannel useAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local
{
    if ((self = [super init])) {
		_channel = theChannel;
		_queue = theQueue;
		
		amqp_basic_consume_ok_t *response = amqp_basic_consume(_channel.connection.internalConnection, _channel.internalChannel, _queue.internalQueue, AMQP_EMPTY_BYTES, !local, !ack, exclusive, amqp_empty_table);
		[_channel.connection checkLastOperation:@"Failed to start consumer"];
		
		_internalConsumer = amqp_bytes_malloc_dup(response->consumer_tag);
	}
	
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(_internalConsumer);
}

- (AMQPMessage *)pop
{
	amqp_frame_t frame;
	int result = -1;
	size_t receivedBytes = 0;
	size_t bodySize = -1;
	amqp_bytes_t body;
	amqp_basic_deliver_t *delivery;
	amqp_basic_properties_t *properties;
	
	AMQPMessage *message = nil;
	
	amqp_maybe_release_buffers(_channel.connection.internalConnection);
	
	while(!message) {
		// a complete message delivery consists of at least three frames:
		
		// Frame #1: method frame with method basic.deliver
		result = amqp_simple_wait_frame(_channel.connection.internalConnection, &frame);
		if (result < 0) {
            return nil;
        }
		
		if (frame.frame_type != AMQP_FRAME_METHOD || frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD) {
            continue;
        }
		
		delivery = (amqp_basic_deliver_t*)frame.payload.method.decoded;
		
		// Frame #2: header frame containing body size
		result = amqp_simple_wait_frame(_channel.connection.internalConnection, &frame);
		if (result < 0) {
            return nil;
        }
		
		if (frame.frame_type != AMQP_FRAME_HEADER) {
			return nil;
		}
		
		properties = (amqp_basic_properties_t*)frame.payload.properties.decoded;
		
		bodySize = (size_t)frame.payload.properties.body_size;
		receivedBytes = 0;
		body = amqp_bytes_malloc(bodySize);
		
		// Frame #3+: body frames
		while(receivedBytes < bodySize) {
			result = amqp_simple_wait_frame(_channel.connection.internalConnection, &frame);
			if (result < 0) {
                return nil;
            }
			
			if (frame.frame_type != AMQP_FRAME_BODY) {
				return nil;
			}
			
            //Next Line is Julians fix for large messages
            void *body_ptr = (char *)body.bytes + receivedBytes;
            receivedBytes += frame.payload.body_fragment.len;
            //New Line
            memcpy(body_ptr, frame.payload.body_fragment.bytes, frame.payload.body_fragment.len);
            //Original Line
            //memcpy(body.bytes, frame.payload.body_fragment.bytes, frame.payload.body_fragment.len);
		}
		
		message = [AMQPMessage messageFromBody:body withDeliveryProperties:delivery withMessageProperties:properties receivedAt:[NSDate date]];
		
		amqp_bytes_free(body);
	}
	
	return message;
}

- (BOOL)ack:(AMQPMessage *)message
{
    return [self ack:message multiple:NO];
}

- (BOOL)ack:(AMQPMessage *)message multiple:(BOOL)multiple
{
   return amqp_basic_ack(_channel.connection.internalConnection, _channel.internalChannel, message.deliveryTag, multiple);
}

- (BOOL)reject:(AMQPMessage *)message requeue:(BOOL)requeue
{
    return amqp_basic_reject(_channel.connection.internalConnection, _channel.internalChannel, message.deliveryTag, requeue);
}



@end
