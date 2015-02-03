//
//  AMQPQueue.h
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

#import <Foundation/Foundation.h>
#import <amqp.h>

@class AMQPChannel;
@class AMQPExchange;
@class AMQPConsumer;

@interface AMQPQueue : NSObject

@property (readonly) AMQPChannel *channel;

- (id)initWithName:(NSString *)theName onChannel:(AMQPChannel *)theChannel isPassive:(BOOL)passive isExclusive:(BOOL)exclusive isDurable:(BOOL)durable getsAutoDeleted:(BOOL)autoDelete;

- (void)bindToExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey;
- (void)unbindFromExchange:(AMQPExchange *)theExchange withKey:(NSString *)bindingKey;

- (void)deleteQueue;

- (AMQPConsumer *)startConsumerWithAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local;

@end
