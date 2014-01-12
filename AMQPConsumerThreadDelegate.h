//
//  AMQPConsumerThreadDelegate.h
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

@class AMQPConsumerThread;
@class AMQPMessage;
@protocol AMQPConsumerThreadDelegate <NSObject>

@required
- (void)amqpConsumerThread:(AMQPConsumerThread *)thread didReceiveNewMessage:(AMQPMessage *)message;
- (void)amqpConsumerThread:(AMQPConsumerThread *)thread didFailWithError:(NSError *)error;
- (void)amqpConsumerThread:(AMQPConsumerThread *)thread reportedError:(NSError *)error;

@optional
- (void)amqpConsumerThreadDidStart:(AMQPConsumerThread *)thread;
- (void)amqpConsumerThreadDidStop:(AMQPConsumerThread *)thread;
- (void)amqpConsumerThread:(AMQPConsumerThread *)thread didReceiveMessage:(AMQPMessage *)message;

@end
