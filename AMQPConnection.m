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
#import <socket.h>
//#import <sys/poll.h>

#import "AMQPConnection.h"

#import "amqp.h"
#import "amqp_framing.h"

#import "AMQPChannel.h"

////////////////////////////////////////////////////////////////////////////////
// Exceptions
////////////////////////////////////////////////////////////////////////////////
NSString *const kAMQPConnectionException    = @"AMQPConnectionException";
NSString *const kAMQPLoginException         = @"AMQPLoginException";
NSString *const kAMQPOperationException     = @"AMQPException";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation AMQPConnection

@synthesize internalConnection = connection;


- (id)init
{
	if(self = [super init])
	{
		connection = amqp_new_connection();
		nextChannel = 1;
	}
	
	return self;
}
- (void)dealloc
{
//	[self disconnect];
	
	amqp_destroy_connection(connection);
	
	[super dealloc];
}

- (void)connectToHost:(NSString*)host onPort:(int)port
{
	socketFD = amqp_open_socket([host UTF8String], port);
    fcntl(socketFD, F_SETFL, O_NONBLOCK);
    fcntl(socketFD, F_SETFL, O_ASYNC);
    fcntl(socketFD, F_SETNOSIGPIPE, 1);

    ////////////////////////////////////////////////////////////////////////////////
    // SETUP TCP KEEPALIVE
    ////////////////////////////////////////////////////////////////////////////////
//    int optval = 1;
//    socklen_t optlen = sizeof(optval);
//    if(setsockopt(socketFD, SOL_SOCKET, SO_KEEPALIVE, &optval, optlen) < 0) {
//        NSLog(@"<error: failed to set SO_KEEPALIVE>");
//    }
//    if(getsockopt(socketFD, SOL_SOCKET, SO_KEEPALIVE, &optval, &optlen) < 0) {
//        NSLog(@"<error: failed to check value for SO_KEEPALIVE>");
//    }
	
	if(socketFD < 0)
	{
		[NSException raise:kAMQPConnectionException format:@"Unable to open socket to host %@ on port %d", host, port];
	}

	amqp_set_sockfd(connection, socketFD);
}
- (void)loginAsUser:(NSString*)username withPassword:(NSString*)password onVHost:(NSString*)vhost
{
	amqp_rpc_reply_t reply = amqp_login(connection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
	
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		[NSException raise:kAMQPLoginException format:@"Failed to login to server as user %@ on vhost %@ using password %@: %@", username, vhost, password, [self errorDescriptionForReply:reply]];
	}
}
- (void)disconnect
{
	amqp_rpc_reply_t reply = amqp_connection_close(connection, AMQP_REPLY_SUCCESS);
	close(socketFD);
	
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		[NSException raise:kAMQPConnectionException format:@"Unable to disconnect from host: %@", [self errorDescriptionForReply:reply]];
	}
	
}

- (void)checkLastOperation:(NSString*)context
{
	amqp_rpc_reply_t reply = amqp_get_rpc_reply(connection);
	
	if(reply.reply_type != AMQP_RESPONSE_NORMAL)
	{
		[NSException raise:kAMQPOperationException format:@"%@: %@", context, [self errorDescriptionForReply:reply]];
	}
}

- (AMQPChannel*)openChannel
{
	AMQPChannel *channel = [[AMQPChannel alloc] init];
	[channel openChannel:nextChannel onConnection:self];
	
	nextChannel++;

	return [channel autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// TODO: output errors
////////////////////////////////////////////////////////////////////////////////
- (BOOL)checkConnection
{
//    NSLog(@"<amqp_connection (%p) :: checking connection...>", self);
    
    int result = -1;
    
//    struct pollfd pfd;
//    pfd.fd = socketFD;
//    pfd.events = POLLIN | POLLHUP | POLLRDNORM;
//    pfd.revents = 0;
//    
//    result = poll(&pfd, 1, 100);
//    NSLog(@"poll result = %d", result);
//    if(result <= 0) {
//        return;
//    }
    
    char buffer[128];
    result = recv(socketFD, &buffer, sizeof(buffer), MSG_PEEK | MSG_DONTWAIT);
    if(result >= 0) {
        NSLog(@"<amqp_connection (%p) :: connection closed!>", self);
        return NO;
    }
    return YES;
}

@end
