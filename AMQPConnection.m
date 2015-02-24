//
//  AMQPConnection.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 19/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQPConnection+Private.h"
#import "AMQPError.h"

#import "amqp_cfstream_socket_objc.h"
#import "amqp_tcp_socket.h"

@interface AMQPConnection ()

@end

@implementation AMQPConnection

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port SSL:(BOOL)SSL allowCellular:(BOOL)allowCellular
{
    NSParameterAssert(host);
    
    self = [super init];
    if (self) {
        _host = [host copy];
        _port = port;
        _SSL = SSL;
        _allowCellular = allowCellular;
        _connectionQueue = dispatch_queue_create("com.amqpkit.connection", DISPATCH_QUEUE_SERIAL);
        _networkThread = [[AMQPNetworkThread alloc] init];
        [_networkThread start];
        [_networkThread scheduleBlock:^{
            _internalConnection = amqp_new_connection();
        }];
        __typeof(self) __weak weakSelf = self;
        [_networkThread scheduleThreadExitBlock:^{
            __typeof(self) __strong self = weakSelf;
            if (self) {
                amqp_destroy_connection(self->_internalConnection);
            }
        }];
        [_networkThread scheduleThreadExitBlock:^{
            __typeof(self) __strong self = weakSelf;
            [self disconnect];
        }];
    }
    return self;
}

- (void)dealloc
{
    [_networkThread cancel];
}

- (NSError *)connectWithUser:(NSString *)user password:(NSString *)password vhost:(NSString *)vhost
{
    // Remove and destroy resources for any open sockets.
    if (_internalSocket) {
        // discard error
        [self disconnect];
    }
    
    
    _internalSocket = amqp_cfstream_socket_new(_internalConnection, ^(CFWriteStreamRef w, CFReadStreamRef r){
        
        if (self.SSL) {
            NSDictionary *settings = @{
                (id)kCFStreamSSLLevel: (id)kCFStreamSocketSecurityLevelNegotiatedSSL
        };
            
            CFReadStreamSetProperty(r, kCFStreamPropertySSLSettings, (CFDictionaryRef)settings);
            CFWriteStreamSetProperty(w, kCFStreamPropertySSLSettings, (CFDictionaryRef)settings);
        }
        
    });
//    _internalSocket = amqp_tcp_socket_new(_internalConnection);
    if (!_internalSocket) {
        return [AMQPError errorWithCode:AMQPErrorCodeSockInitError format:@"Unable to create new socket."];
	}
    static const __darwin_time_t kSocketOpenTimeout = 30;
    struct timeval *timeout = &(struct timeval){ .tv_sec = kSocketOpenTimeout, .tv_usec = 0 };
    int status = amqp_socket_open_noblock(_internalSocket, [self.host UTF8String], (int)self.port, timeout);
	if (status != AMQP_STATUS_OK) {
        _internalSocket = NULL;
        return [AMQPError errorWithCode:status format:@"Unable to open socket."];
	}
    
    NSError *loginError = [self loginAsUser:user withPassword:password onVHost:vhost];
    
    return loginError;
}


- (NSError *)loginAsUser:(NSString *)username withPassword:(NSString *)password onVHost:(NSString *)vhost
{
	amqp_rpc_reply_t reply = amqp_login(self.internalConnection, [vhost UTF8String], 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, [username UTF8String], [password UTF8String]);
	
	if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        return [AMQPError errorWithCode:AMQPErrorCodeSockError reply_t:reply];
	}
    
    return nil;
}

- (AMQPMaybe *)openChannel
{
    self.channelCount++;
    
	AMQPChannel *channel = [[AMQPChannel alloc] init];
    
    NSError *error = [channel openChannel:self.channelCount onConnection:(id)self];
    if (error) {
        return [AMQPMaybe error:error];
    }
    return [AMQPMaybe value:channel];
}

- (void)checkLastOperation:(NSString *)context
{
    //  do nothing for the moment
}

- (AMQPError *)lastRPCReplyError
{
    amqp_rpc_reply_t reply = amqp_get_rpc_reply(self.internalConnection);
    // We can do better
    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        return [AMQPError errorWithCode:AMQPErrorCodeServerError reply_t:reply];
    }
    return nil;
}

- (BOOL)check
{
    return YES;
}

- (NSError *)disconnect
{
    amqp_rpc_reply_t reply = amqp_connection_close(_internalConnection, AMQP_REPLY_SUCCESS);
    _internalSocket = NULL;
    if (reply.reply_type != AMQP_RESPONSE_NORMAL) {
        return [AMQPError errorWithCode:AMQPErrorCodeSockError reply_t:reply];
    }
    return nil;
}

#pragma mark - Non Blocking Async Methods

- (void)disconnect:(void (^)(NSError *))completionBlock
{
    [self.networkThread scheduleBlock:^{
        NSError *error = [self disconnect];
        if (completionBlock) {
            completionBlock(error);
        }
    }];
}

- (void)connectWithUser:(NSString *)user password:(NSString *)password vhost:(NSString *)vhost queue:(dispatch_queue_t)queue completion:(void (^)(NSError *))completionBlock
{
    NSParameterAssert(completionBlock);
    
    [self.networkThread scheduleBlock:^{
        NSError *error = [self connectWithUser:user password:password vhost:vhost];
        completionBlock(error);
    }];
}

- (void)openChannel:(void (^)(AMQPChannel *, NSError *))completionBlock
{
    [self.networkThread scheduleBlock:^{
        AMQPMaybe *channel = [self openChannel];
        if (completionBlock) {
            completionBlock(channel.value, channel.error);
        }
    }];
}


@end
