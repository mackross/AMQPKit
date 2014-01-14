//
//  AMQPChannel.m
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

#import "AMQPChannel.h"

# import "amqp.h"
# import "amqp_framing.h"

@interface AMQPChannel ()

@property (assign, readwrite) amqp_channel_t internalChannel;
@property (strong, readwrite) AMQPConnection *connection;

@end

@implementation AMQPChannel

- (id)init
{
    self = [super init];
	if (self) {
		_internalChannel = -1;
	}
	
	return self;
}

- (void)dealloc
{
    [self close];
}

- (void)openChannel:(unsigned int)channel onConnection:(AMQPConnection *)connection
{
	_connection = connection;
	_internalChannel = channel;
	
	amqp_channel_open(_connection.internalConnection, _internalChannel);
	
	[_connection checkLastOperation:@"Failed to open a channel"];
}

- (void)close
{
    amqp_channel_close(_connection.internalConnection, _internalChannel, AMQP_REPLY_SUCCESS);
}

@end
