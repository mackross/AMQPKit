//
//  AMQPConnection.h
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 19/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMQPChannel;

@interface AMQPConnection : NSObject

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port SSL:(BOOL)SSL allowCellular:(BOOL)allowCellular;

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSString *user;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic, readonly) BOOL SSL;
@property (nonatomic, readonly) BOOL allowCellular;
@property (nonatomic, readonly, getter=isCellular) BOOL cellular;

/// Opens a socket connection using the instance's configuration variables
/// and the credential arguments.
- (void)connectWithUser:(NSString *)user password:(NSString *)password vhost:(NSString *)vhost queue:(dispatch_queue_t)queue completion:(void(^)(NSError *error))completionBlock;

- (void)openChannel:(void(^)(AMQPChannel *channel, NSError *error))completionBlock;

- (void)disconnect:(void(^)(NSError *))completionBlock;

@end
