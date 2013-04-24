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

# import "amqp.h"
# import "amqp_framing.h"

# import "AMQPChannel.h"
# import "AMQPExchange.h"
# import "AMQPConsumer.h"

uint16_t amqp_queue_ttl = 60000;
uint16_t amqp_queue_msg_ttl = 60000;

@implementation AMQPQueue

@synthesize internalQueue = queueName;

- (id)initWithName:(NSString*)theName
         onChannel:(AMQPChannel*)theChannel
         isPassive:(BOOL)passive
       isExclusive:(BOOL)exclusive
         isDurable:(BOOL)durable
   getsAutoDeleted:(BOOL)autoDelete
{
	if(self = [super init]) {
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

		amqp_queue_declare_ok_t *declaration = amqp_queue_declare(theChannel.connection.internalConnection,
                                                                  theChannel.internalChannel,
                                                                  amqp_cstring_bytes([theName UTF8String]),
                                                                  passive,
                                                                  durable,
                                                                  exclusive,
                                                                  autoDelete,
                                                                  queue_args);
		
		[theChannel.connection checkLastOperation:@"Failed to declare queue"];
		
		queueName = amqp_bytes_malloc_dup(declaration->queue);
		channel = [theChannel retain];
	}
	
	return self;
}
- (void)dealloc
{
	amqp_bytes_free(queueName);
	[channel release];
	
	[super dealloc];
}

- (void)bindToExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey
{
	amqp_queue_bind(channel.connection.internalConnection,
                    channel.internalChannel,
                    queueName,
                    theExchange.internalExchange,
                    amqp_cstring_bytes([bindingKey UTF8String]),
                    AMQP_EMPTY_TABLE);
	
	[channel.connection checkLastOperation:@"Failed to bind queue to exchange"];
}
- (void)unbindFromExchange:(AMQPExchange*)theExchange withKey:(NSString*)bindingKey
{
//    if([channel.connection checkConnection]) {
        amqp_queue_unbind(channel.connection.internalConnection,
                          channel.internalChannel,
                          queueName,
                          theExchange.internalExchange,
                          amqp_cstring_bytes([bindingKey UTF8String]),
                          AMQP_EMPTY_TABLE);
//    }
//    else {
//        NSLog(@"<amqp_queue: error: unable to unbind queue from exchange due to disconnection>");
//        [NSException raise:kAMQPOperationException format:@"%@: %@", @"AMQPQueue", @"Unable to unbind queue from exchange. Connection lost."];
//    }
	
	[channel.connection checkLastOperation:@"Failed to unbind queue from exchange"];
}

- (AMQPConsumer*)startConsumerWithAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local
{
	AMQPConsumer *consumer = [[AMQPConsumer alloc] initForQueue:self
                                                      onChannel:channel
                                            useAcknowledgements:ack
                                                    isExclusive:exclusive
                                           receiveLocalMessages:local];
	
	return [consumer autorelease];
}

- (void)deleteQueue
{
    amqp_queue_delete(channel.connection.internalConnection,
                      channel.internalChannel,
                      queueName, TRUE,
                      TRUE);
    [channel.connection checkLastOperation:@"Failed to delete queue"];
}

@end
