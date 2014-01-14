//
//  AMQPMessage.m
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

#import "AMQPMessage.h"

# import "amqp.h"
# import "amqp_framing.h"

# define AMQP_BYTES_TO_NSSTRING(x) [[NSString alloc] initWithBytes:x.bytes length:x.len encoding:NSUTF8StringEncoding]

@implementation AMQPMessage

+ (AMQPMessage*)messageFromBody:(amqp_bytes_t)theBody withDeliveryProperties:(amqp_basic_deliver_t *)theDeliveryProperties withMessageProperties:(amqp_basic_properties_t *)theMessageProperties receivedAt:(NSDate *)receiveTimestamp
{
	AMQPMessage *message = [[AMQPMessage alloc] initWithBody:theBody withDeliveryProperties:theDeliveryProperties withMessageProperties:theMessageProperties receivedAt:receiveTimestamp];
	return message;
}

- (id)initWithBody:(amqp_bytes_t)theBody withDeliveryProperties:(amqp_basic_deliver_t *)theDeliveryProperties withMessageProperties:(amqp_basic_properties_t *)theMessageProperties receivedAt:(NSDate *)receiveTimestamp
{
	if (!theDeliveryProperties || !theMessageProperties) {
        return nil;
    }
	
    if ((self = [super init])) {
		_consumerTag = AMQP_BYTES_TO_NSSTRING(theDeliveryProperties->consumer_tag);
		_deliveryTag = theDeliveryProperties->delivery_tag;
		_redelivered = theDeliveryProperties->redelivered;
		_exchangeName = AMQP_BYTES_TO_NSSTRING(theDeliveryProperties->exchange);
		_routingKey = AMQP_BYTES_TO_NSSTRING(theDeliveryProperties->routing_key);
		
		if (theMessageProperties->_flags & AMQP_BASIC_CONTENT_TYPE_FLAG) { _contentType = AMQP_BYTES_TO_NSSTRING(theMessageProperties->content_type); } else { _contentType = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_CONTENT_ENCODING_FLAG) { _contentEncoding = AMQP_BYTES_TO_NSSTRING(theMessageProperties->content_encoding); } else { _contentEncoding = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_HEADERS_FLAG) { _headers = theMessageProperties->headers; } else { _headers = AMQP_EMPTY_TABLE; }
		if (theMessageProperties->_flags & AMQP_BASIC_DELIVERY_MODE_FLAG) { _deliveryMode = theMessageProperties->delivery_mode; } else { _deliveryMode = 0; }
		if (theMessageProperties->_flags & AMQP_BASIC_PRIORITY_FLAG) { _priority = theMessageProperties->priority; } else { _priority = 0; }
		if (theMessageProperties->_flags & AMQP_BASIC_CORRELATION_ID_FLAG) { _correlationID = AMQP_BYTES_TO_NSSTRING(theMessageProperties->correlation_id); } else { _correlationID = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_REPLY_TO_FLAG) { _replyToQueueName = AMQP_BYTES_TO_NSSTRING(theMessageProperties->reply_to); } else { _replyToQueueName = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_EXPIRATION_FLAG) { _expiration = AMQP_BYTES_TO_NSSTRING(theMessageProperties->expiration); } else { _expiration = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_MESSAGE_ID_FLAG) { _messageID = AMQP_BYTES_TO_NSSTRING(theMessageProperties->message_id); } else { _messageID = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_TIMESTAMP_FLAG) { _timestamp = theMessageProperties->timestamp; } else { _timestamp = 0; }
		if (theMessageProperties->_flags & AMQP_BASIC_TYPE_FLAG) { _type = AMQP_BYTES_TO_NSSTRING(theMessageProperties->type); } else { _type = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_USER_ID_FLAG) { _userID = AMQP_BYTES_TO_NSSTRING(theMessageProperties->user_id); } else { _userID = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_APP_ID_FLAG) { _appID = AMQP_BYTES_TO_NSSTRING(theMessageProperties->app_id); } else { _appID = nil; }
		if (theMessageProperties->_flags & AMQP_BASIC_CLUSTER_ID_FLAG) { _clusterID = AMQP_BYTES_TO_NSSTRING(theMessageProperties->cluster_id); } else { _clusterID = nil; }
		
		_read = NO;
		_receivedAt = [receiveTimestamp copy];

        if (!_contentType || [_contentType isEqualToString:@"t"]) {
            _body = AMQP_BYTES_TO_NSSTRING(theBody);
        }
        else if ([_contentType isEqualToString:@"b"]) {
            _data = [NSData dataWithBytes:theBody.bytes length:theBody.len];
        }
        else {
            _body = AMQP_BYTES_TO_NSSTRING(theBody);
        }
	}
	
	return self;
}

- (id)initWithAMQPMessage:(AMQPMessage *)theMessage
{
    if ((self = [super init])) {
		_body = [theMessage.body copy];
        _data = [theMessage.data copy];
		
		_consumerTag = [theMessage.consumerTag copy];
		_deliveryTag = theMessage.deliveryTag;
		_redelivered = theMessage.redelivered;
		_exchangeName = [theMessage.exchangeName copy];
		_routingKey = [theMessage.routingKey copy];
		
		_contentType = [theMessage.contentType copy];
		_contentEncoding = [theMessage.contentEncoding copy];
		_headers = theMessage.headers;
		_deliveryMode = theMessage.deliveryMode;
		_priority = theMessage.priority;
		_correlationID = [theMessage.correlationID copy];
		_replyToQueueName = [theMessage.replyToQueueName copy];
		_expiration = [theMessage.expiration copy];
		_messageID = [theMessage.messageID copy];
		_timestamp = theMessage.timestamp;
		_type = [theMessage.type copy];
		_userID = [theMessage.userID copy];
		_appID = [theMessage.appID copy];
		_clusterID = [theMessage.clusterID copy];
		
		_read = theMessage.read;
		_receivedAt = [theMessage.receivedAt copy];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone*)zone
{
	AMQPMessage *newMessage = [[AMQPMessage allocWithZone:zone] initWithAMQPMessage:self];
	return newMessage;
}

@end
