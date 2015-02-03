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

#import "amqp.h"
#import "amqp_tcp_socket.h"
#import "amqp_socket.h"

#import "AMQPConnection.h"
#import "AMQPErrorDecoder.h"

#import "AMQPChannel.h"

NSString *const kAMQPConnectionException    = @"AMQPConnectionException";
NSString *const kAMQPLoginException         = @"AMQPLoginException";
NSString *const kAMQPOperationException     = @"AMQPException";

@implementation AMQPConnection
{
    amqp_connection_state_t _internalConnection;
    amqp_socket_t *_socket;

    amqp_channel_t _nextChannel;
}

- (instancetype)init
{
    if ((self = [super init])) {
		_internalConnection = amqp_new_connection();
        if (!_internalConnection) {
            [NSException raise:kAMQPConnectionException format:@"Unable to create a new AMQP connection"];
        }
        _socket = NULL;

		_nextChannel = 1;
	}
	
	return self;
}

- (void)dealloc
{
    @try {
        [self disconnect];
    }
    @catch (NSException *exception) {
        NSLog(@"[AMQPConnection] Problem disconnecting: %@", exception);
    }
    @finally {
        amqp_destroy_connection(_internalConnection);
    }
}

- (void)connectToHost:(NSString *)host onPort:(int)port
{
    const __darwin_time_t kSocketOpenTimeout = 30;

    struct timeval *timeout = malloc(sizeof(struct timeval));
    if (!timeout) {
        [NSException raise:kAMQPConnectionException format:@"Out of memory"];
    }
    timeout->tv_sec = kSocketOpenTimeout;
    timeout->tv_usec = 0;

    _socket = amqp_tcp_socket_new(_internalConnection);
    if (!_socket) {
        _socket = NULL;
		[NSException raise:kAMQPConnectionException format:@"Unable to create a TCP socket"];
	}

    int status = amqp_socket_open_noblock(_socket, [host UTF8String], port, timeout);
	if (status != AMQP_STATUS_OK) {
        amqp_rpc_reply_t reply = amqp_connection_close(_internalConnection, AMQP_REPLY_SUCCESS);
        if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
            NSLog(@"DEBUG: Problem closing the connection: %@", [AMQPErrorDecoder errorDescriptionForReply:reply]);
        }
        _socket = NULL;

		[NSException raise:kAMQPConnectionException format:@"Unable to open a TCP socket to host %@ on port %d. Error: %@ (%d)", host, port, [NSString stringWithUTF8String:amqp_error_string2(status)], status];
	}
}

- (void)loginAsUser:(NSString *)username withPassword:(NSString *)password onVHost:(NSString *)vhost
{
	amqp_rpc_reply_t reply = amqp_login(_internalConnection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPLoginException format:@"Failed to login to server as user %@ on vhost %@ using password %@: %@", username, vhost, password, [AMQPErrorDecoder errorDescriptionForReply:reply]];
	}
}

- (void)disconnect
{
    if (!_socket) {
        [NSException raise:kAMQPConnectionException format:@"Unable to disconnect from host: this instance of AMQPConnection has not been connected yet or the connection previously failed."];
    }

    amqp_rpc_reply_t reply = amqp_connection_close(_internalConnection, AMQP_REPLY_SUCCESS);

	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPConnectionException format:@"Unable to disconnect from host: %@", [AMQPErrorDecoder errorDescriptionForReply:reply]];
	}

    _socket = NULL;
}

- (void)checkLastOperation:(NSString *)context
{
	amqp_rpc_reply_t reply = amqp_get_rpc_reply(_internalConnection);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
		[NSException raise:kAMQPOperationException format:@"%@: %@", context, [AMQPErrorDecoder errorDescriptionForReply:reply]];
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

//    char buffer[128];
//    int result = recv(_socketFD, buffer, sizeof(buffer), MSG_PEEK | MSG_DONTWAIT);
//    BOOL peerClosedConnection = (result == 0);
//    if (peerClosedConnection) {
//        return NO;
//    }
//    BOOL errorOccurred = (result == -1);
//    BOOL noDataToReadTimeout = (errno == EAGAIN);
//    if (errorOccurred) {
//        if (noDataToReadTimeout) {
//            return YES;
//        } else {
//            return NO;
//        }
//    }
    return YES;
}

@end
