//
//  AMQPConsumer.h
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
#import "amqp.h"

@class AMQPChannel;
@class AMQPQueue;
@class AMQPMessage;

@interface AMQPConsumer : NSObject

@property (readonly) AMQPChannel *channel;
@property (readonly) AMQPQueue *queue;

- (id)initForQueue:(AMQPQueue *)theQueue onChannel:(AMQPChannel *)theChannel useAcknowledgements:(BOOL)ack isExclusive:(BOOL)exclusive receiveLocalMessages:(BOOL)local;
- (void)dealloc;

- (AMQPMessage *)pop;
- (BOOL)ack:(AMQPMessage *)message;


/// all previous messages are acked too
- (BOOL)ack:(AMQPMessage *)message multiple:(BOOL)multiple;

- (BOOL)reject:(AMQPMessage *)message requeue:(BOOL)requeue;

@end
