//
//  AMQPNetworkThread.h
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 23/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMQPNetworkThread : NSThread

// Schedules block and blocks caller until completion.
- (void)runBlock:(dispatch_block_t)block;

- (void)scheduleBlock:(dispatch_block_t)block;

// Blocks are run in reverse order before the thread exits. Useful for cleaning
// up resources when cancel is called.
- (void)scheduleThreadExitBlock:(dispatch_block_t)block;
@end
