//
//  AMQPQueue.m
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

#import "AMQPQueue.h"
#import "AMQP+Private.h"

#import "AMQPChannel.h"
#import "AMQPError.h"
#import "AMQPExchange.h"
#import "AMQPConsumer.h"
#import "AMQPConnection+Private.h"
#import "AMQPMessage.h"

uint16_t amqp_queue_ttl = 60000;
uint16_t amqp_queue_msg_ttl = 60000;

@interface AMQPQueue ()

@property (nonatomic, readonly) AMQPConnection *connection;
@property (strong, readwrite) AMQPChannel *channel;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, getter=isPassive) BOOL passive;
@property (nonatomic, readonly, getter=isExclusive) BOOL exclusive;
@property (nonatomic, readonly, getter=isDurable) BOOL durable;
@property (nonatomic, readonly, getter=isAutoDeleted) BOOL autoDeleted;

@end

@implementation AMQPQueue

- (AMQPConnection *)connection
{
    return self.channel.connection;
}
- (void)dealloc
{
	amqp_bytes_free(_internalQueue);
}

- (id)initWithName:(NSString *)theName
         onChannel:(AMQPChannel *)theChannel
         isPassive:(BOOL)passive
       isExclusive:(BOOL)exclusive
         isDurable:(BOOL)durable
   getsAutoDeleted:(BOOL)autoDelete
{
    if ((self = [super init])) {
        _name = theName;
        _channel = theChannel;
        _passive = passive;
        _exclusive = exclusive;
        _durable = durable;
        _autoDeleted = autoDelete;
        
	}
	
	return self;
}

- (NSError *)declare
{
    
        amqp_table_t queue_args;
        amqp_table_entry_t entries[2];
        
        entries[0].key = amqp_cstring_bytes("x-message-ttl");
        entries[0].value.kind = AMQP_FIELD_KIND_I32;
        entries[0].value.value.i32 = amqp_queue_msg_ttl;
        
        entries[1].key = amqp_cstring_bytes("x-expires");
        entries[1].value.kind = AMQP_FIELD_KIND_I32;
        entries[1].value.value.i32 = amqp_queue_ttl;
        
        queue_args.num_entries = 2;
        queue_args.entries = entries;

		amqp_queue_declare_ok_t *declaration = amqp_queue_declare(self.connection.internalConnection,
                                                                  self.channel.internalChannel,
                                                                  amqp_cstring_bytes([self.name UTF8String]),
                                                                  self.passive,
                                                                  self.durable,
                                                                  self.exclusive,
                                                                  self.autoDeleted,
                                                                  queue_args);
		
    if (!declaration) {
        // TODO: fix up the errors
        amqp_rpc_reply_t reply = amqp_get_rpc_reply(self.connection.internalConnection);
        return [AMQPError errorWithCode:AMQPErrorCodeServerError reply_t:reply];
    }
    _internalQueue = amqp_bytes_malloc_dup(declaration->queue);
    return nil;
}

- (NSError *)bindToExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey
{
	amqp_queue_bind_ok_t *result = amqp_queue_bind(self.channel.connection.internalConnection,
                    self.channel.internalChannel,
                    self.internalQueue,
                    theExchange.internalExchange,
                    amqp_cstring_bytes([bindingKey UTF8String]),
                    AMQP_EMPTY_TABLE);
    if (!result) {
        // TODO: fix errors I can do better (format maybe?)
        return [self.connection lastRPCReplyError];
    }
	
    return nil;
}

- (NSError *)unbindFromExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey
{
    amqp_queue_unbind_ok_t *result = amqp_queue_unbind(self.channel.connection.internalConnection,
                      self.channel.internalChannel,
                      self.internalQueue,
                      theExchange.internalExchange,
                      amqp_cstring_bytes([bindingKey UTF8String]),
                      AMQP_EMPTY_TABLE);
	
    if (!result) {
        // TODO: fix errors I can do better (format maybe?)
        return [self.connection lastRPCReplyError];
    }
	
    return nil;
}

- (AMQPMaybe *)getMessageWithAutoAcknowledgement:(BOOL)autoAck

{
   amqp_rpc_reply_t reply = amqp_basic_get(self.connection.internalConnection, self.channel.internalChannel, self.internalQueue, autoAck);
    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        // TODO: WRONG!
        return [AMQPMaybe error:[AMQPError errorWithCode:AMQPErrorCodeServerError reply_t:reply]];
    } else if (reply.reply.id == AMQP_BASIC_GET_EMPTY_METHOD) {
        return [AMQPMaybe value:nil];
    }
    
    amqp_message_t message;
    reply = amqp_read_message(self.connection.internalConnection, self.channel.internalChannel, &message, 0);
    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        // TODO: WRONG!
        return [AMQPMaybe error:[AMQPError errorWithCode:AMQPErrorCodeServerError reply_t:reply]];
    }
    AMQPMessage *msg = [[AMQPMessage alloc] initWithBody:message.body withDeliveryProperties:NULL withMessageProperties:&message.properties receivedAt:[NSDate date]];
    amqp_destroy_message(&message);
    return [AMQPMaybe value:msg];
}

- (void)getMessageWithAutoAcknowledgement:(BOOL)autoAck completion:(void (^)(AMQPMessage *, NSError *))completionBlock
{
    [self.connection.networkThread scheduleBlock:^{
        AMQPMaybe *maybe = [self getMessageWithAutoAcknowledgement:autoAck];
        if (completionBlock) {
            completionBlock(maybe.value, maybe.error);
        }
    }];
}

- (AMQPConsumer *)startConsumerWithAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local
{
	AMQPConsumer *consumer = [[AMQPConsumer alloc] initForQueue:self
                                                      onChannel:self.channel
                                            useAcknowledgements:ack
                                                    isExclusive:exclusive
                                           receiveLocalMessages:local];
	
	return consumer;
}

- (void)deleteQueue
{
    amqp_queue_delete(self.channel.connection.internalConnection,
                      self.channel.internalChannel,
                      self.internalQueue, TRUE,
                      TRUE);
    
    [self.channel.connection checkLastOperation:@"Failed to delete queue"];
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

- (void)bindToExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey completion:(void (^)(NSError *))completionBlock
{
    [self.connection.networkThread scheduleBlock:^{
        NSError *error = [self bindToExchange:theExchange withKey:bindingKey];
        if (completionBlock) {
            completionBlock(error);
        }
    }];
}

- (void)unbindFromExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey completion:(void (^)(NSError *))completionBlock
{
   [self.connection.networkThread scheduleBlock:^{
       // TODO: fix this up to store state so you don't have to pass in arguments...
       NSError *error = [self unbindFromExchange:theExchange withKey:bindingKey];
        if (completionBlock) {
            completionBlock(error);
        }
   }];
}

@end
