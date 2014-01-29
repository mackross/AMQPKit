//
//  AMQPConnection.m
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

#import <unistd.h>
#import <netinet/tcp.h>

#import <sys/socket.h>

#import "AMQPConnection.h"
#import "AMQPChannel.h"

NSString *const kAMQPConnectionException    = @"AMQPConnectionException";
NSString *const kAMQPLoginException         = @"AMQPLoginException";
NSString *const kAMQPOperationException     = @"AMQPException";

@interface AMQPConnection ()

@property (assign, readwrite) amqp_connection_state_t internalConnection;

@end

@implementation AMQPConnection
{
	int _socketFD;
	unsigned int _nextChannel;
}

- (id)init
{
    if ((self = [super init])) {
		_internalConnection = amqp_new_connection();
		_nextChannel = 1;
	}
	
	return self;
}

- (void)dealloc
{
    // this was commented by pdcgomes on 23 January 2013 in [bab486a], to verify
    // [self disconnect];
	
	amqp_destroy_connection(_internalConnection);
}

- (void)connectToHost:(NSString *)host onPort:(int)port
{
	_socketFD = amqp_open_socket([host UTF8String], port);
    fcntl(_socketFD, F_SETFL, O_NONBLOCK);
    fcntl(_socketFD, F_SETFL, O_ASYNC);
    fcntl(_socketFD, F_SETNOSIGPIPE, 1);
    
	if (_socketFD < 0) {
		[NSException raise:kAMQPConnectionException format:@"Unable to open socket to host %@ on port %d", host, port];
	}

	amqp_set_sockfd(_internalConnection, _socketFD);
}

- (void)loginAsUser:(NSString *)username withPassword:(NSString *)password onVHost:(NSString *)vhost
{
	amqp_rpc_reply_t reply = amqp_login(_internalConnection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPLoginException format:@"Failed to login to server as user %@ on vhost %@ using password %@: %@", username, vhost, password, [self errorDescriptionForReply:reply]];
	}
}

- (void)disconnect
{
	amqp_rpc_reply_t reply = amqp_connection_close(_internalConnection, AMQP_REPLY_SUCCESS);
	close(_socketFD);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPConnectionException format:@"Unable to disconnect from host: %@", [self errorDescriptionForReply:reply]];
	}
	
}

- (void)checkLastOperation:(NSString *)context
{
	amqp_rpc_reply_t reply = amqp_get_rpc_reply(_internalConnection);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPOperationException format:@"%@: %@", context, [self errorDescriptionForReply:reply]];
	}
}

- (AMQPChannel *)openChannel
{
	AMQPChannel *channel = [[AMQPChannel alloc] init];
	[channel openChannel:_nextChannel onConnection:self];
	
	_nextChannel++;

	return channel;
}

- (BOOL)check
{
    // https://developer.apple.com/library/ios/documentation/System/Conceptual/ManPages_iPhoneOS/man2/recv.2.html
    
    char buffer[128];
    int result = recv(_socketFD, &buffer, sizeof(buffer), MSG_PEEK | MSG_DONTWAIT);
    BOOL peerClosedConnection = (result == 0);
    if (peerClosedConnection) {
        return NO;
    }
    BOOL errorOccured = (result == -1);
    BOOL noDataToReadTimeout = (errno == EAGAIN);
    if (errorOccured) {
        if (noDataToReadTimeout) {
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

@end
