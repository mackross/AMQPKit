//
//  AMQPConsumerThread.h
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

#import "AMQPConsumerThreadDelegate.h"

@class LAMQPConnection;
@class AMQPChannel;
@class AMQPQueue;
@class AMQPConsumer;
@class AMQPMessage;

@interface AMQPConsumerThread : NSThread

@property (weak) id<AMQPConsumerThreadDelegate> delegate;
@property (readonly, copy) NSString *topic;

- (id)initWithConfiguration:(NSDictionary *)configuration
                exchangeKey:(NSString *)exchangeKey
                      topic:(NSString *)topic
                   delegate:(id<AMQPConsumerThreadDelegate>)delegate
              callbackQueue:(dispatch_queue_t)callbackQueue;

- (void)stop;
- (void)stopNoWait;

@end
