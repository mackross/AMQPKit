//
//  AMQPConnection.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 19/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQPConnection+Private.h"

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
    }
    return self;
}

- (void)connectWithUser:(NSString *)user password:(NSString *)password vhost:(NSString *)vhost completion:(void (^)(NSError *))completionBlock
{
    
}


@end
