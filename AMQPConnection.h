//
//  AMQPConnection.h
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

extern NSString *const kAMQPConnectionException;
extern NSString *const kAMQPLoginException;
extern NSString *const kAMQPOperationException;

@class AMQPChannel;

@interface AMQPConnection : NSObject


- (void)connectToHost:(NSString *)host onPort:(int)port;
- (void)loginAsUser:(NSString *)username withPassword:(NSString *)password onVHost:(NSString *)vhost;
- (void)disconnect; // all channels have to be closed before closing the connection


- (AMQPChannel *)openChannel;

- (BOOL)check;

@end
