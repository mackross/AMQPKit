//
//  AMQPExchange.m
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

#import "AMQPExchange.h"
#import "AMQP+Private.h"
#import "AMQPError.h"
#import "AMQPConnection+Private.h"

#import "AMQPChannel.h"
#import "LAMQPConnection.h"

//#import "config.h"

#define AMQP_EXCHANGE_TYPE_DIRECT   @"direct"
#define AMQP_EXCHANGE_TYPE_FANOUT   @"fanout"
#define AMQP_EXCHANGE_TYPE_TOPIC    @"topic"

@interface AMQPExchange ()

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BOOL isPassive;
@property (nonatomic, readonly) BOOL isDurable;
@property (nonatomic, readonly) BOOL autoDelete;
@property (nonatomic, readonly) BOOL internal;
@property (strong, readwrite) AMQPChannel *channel;
@property (nonatomic, readwrite) AMQPConnection *connection;

@property (nonatomic, readonly) NSString *type;

@end

@implementation AMQPExchange

- (AMQPConnection *)connection
{
    return (id)self.channel.connection;
}

- (void)dealloc
{
	amqp_bytes_free(_internalExchange);
}

- (id)initExchangeOfType:(NSString *)theType withName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete
{
    if ((self = [super init])) {
        _internal = NO;
        _autoDelete = autoDelete;
        _isDurable = durable;
        _isPassive = passive;
        _type = theType;
        
		
		
		_internalExchange = amqp_bytes_malloc_dup(amqp_cstring_bytes([theName UTF8String]));
		_channel = theChannel;
	}
	
	return self;
}

- (void)declare:(void (^)(NSError *))completionBlock
{
    [self.connection.networkThread scheduleBlock:^{
        NSError *error = [self declare];
        if (completionBlock) {
            completionBlock(error);
        }
    }];
}

- (NSError *)declare
{
    amqp_exchange_declare_ok_t *result = amqp_exchange_declare(self.connection.internalConnection, self.channel.internalChannel, self.internalExchange, amqp_cstring_bytes([self.type UTF8String]), self.isPassive, self.isDurable, self.autoDelete, self.internal, AMQP_EMPTY_TABLE);
    if (!result) {
        amqp_rpc_reply_t reply = amqp_get_rpc_reply(self.connection.internalConnection);
// TODO: fix error handling
        [AMQPError errorWithCode:AMQPErrorCodeServerError reply_t:reply];
    }
    return nil;
}

- (id)initDirectExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_DIRECT withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete];
}

- (id)initFanoutExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_FANOUT withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete];
}

- (id)initTopicExchangeWithName:(NSString *)theName onChannel:(AMQPChannel*)theChannel isPassive:(BOOL)passive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete
{
	return [self initExchangeOfType:AMQP_EXCHANGE_TYPE_TOPIC withName:theName onChannel:theChannel isPassive:passive isDurable:durable getsAutoDeleted:autoDelete];
}

- (NSError *)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey
{
	int status = amqp_basic_publish(_channel.connection.internalConnection, _channel.internalChannel, _internalExchange, amqp_cstring_bytes([theRoutingKey UTF8String]), NO, NO, NULL, amqp_cstring_bytes([body UTF8String]));
    if (status != AMQP_STATUS_OK) {
        return [AMQPError errorWithCode:status format:@"Unable to publish method."];
    }
    
    return nil;
	
}

- (void)publishMessage:(NSString *)body usingRoutingKey:(NSString *)theRoutingKey completion:(void (^)(NSError *))completionBlock
{
    [self.connection.networkThread scheduleBlock:^{
        NSError *error = [self publishMessage:body usingRoutingKey:theRoutingKey];
        if (completionBlock) {
            completionBlock(error);
        }
    }];
}

@end
