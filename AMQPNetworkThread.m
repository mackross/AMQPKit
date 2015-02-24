//
//  AMQPNetworkThread.m
//  AMQPKit
//
//  Created by Andrew Mackenzie-Ross on 23/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import "AMQPNetworkThread.h"

@class AMQPBlock;
@interface AMQPNetworkThread ()
@property (nonatomic, readonly) NSTimer *distantFutureTimer;
@property (nonatomic, readwrite) AMQPBlock *head;
@property (nonatomic, readwrite) AMQPBlock *tail;
@property (nonatomic, readonly) NSRunLoop *runloop;

@property (nonatomic, readonly) dispatch_semaphore_t waitForRunloop;
@property (nonatomic, readonly) NSMutableArray *threadExitBlocks;
@end

@interface AMQPBlock : NSObject
- (instancetype)initWithBlock:(dispatch_block_t)block semaphore:(dispatch_semaphore_t)semaphore;
- (void)execute;
@property (nonatomic, readwrite) AMQPBlock *nextBlock;
@end

@implementation AMQPNetworkThread

- (instancetype)init
{
    self = [super init];
    if (self) {
        _waitForRunloop = dispatch_semaphore_create(0);
        _threadExitBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)start
{
    [super start];
}

- (void)main
{
    @autoreleasepool {
     
        _runloop = [NSRunLoop currentRunLoop];
        dispatch_semaphore_signal(self.waitForRunloop);
        _waitForRunloop = nil;
        
        // distantFutureTimer keeps this runloop from disappearing
        
        _distantFutureTimer  = [NSTimer timerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(cancel) userInfo:nil repeats:NO];
        [_runloop addTimer:_distantFutureTimer forMode:NSDefaultRunLoopMode];
        
        while ([_runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            if (self.isCancelled) {
                break;
            }
        }
        
        [self runThreadExitBlocks];
        
        [_distantFutureTimer invalidate];
        _distantFutureTimer = nil;
        _runloop = nil;
        
        [NSThread exit];
    }
}

- (void)runBlock:(dispatch_block_t)block
{
    NSParameterAssert(block);
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [self scheduleBlock:block semaphore:sem];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void)scheduleBlock:(dispatch_block_t)block
{
    [self scheduleBlock:block semaphore:NULL];
}

- (void)scheduleBlock:(dispatch_block_t)block semaphore:(dispatch_semaphore_t)semaphore
{
    NSParameterAssert(block);
    
    if (self.waitForRunloop && dispatch_semaphore_wait(self.waitForRunloop, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC))) != 0) {
        [NSException raise:NSInternalInconsistencyException format:@"Cannot schedule a block until thread is executing and runloop exists."];
    }
    
    AMQPBlock *blockCommand = [[AMQPBlock alloc] initWithBlock:block semaphore:semaphore];
    
    BOOL runHead = NO;
    @synchronized(self) {
        self.tail.nextBlock = blockCommand;
        self.tail = blockCommand;
        if (!self.head) {
            self.head = blockCommand;
            runHead = YES;
        }
    }
    if (runHead) {
        [self performSelector:@selector(runHead) onThread:self withObject:nil waitUntilDone:NO];
    }
}

- (void)runHead
{
    [self.head execute];
    BOOL runHeadAgain = NO;
    @synchronized(self) {
        self.head = self.head.nextBlock;
        runHeadAgain = self.head != nil;
    }
    
    if (runHeadAgain) {
        [self performSelector:@selector(runHead) onThread:self withObject:nil waitUntilDone:NO];
    }
}

- (void)scheduleThreadExitBlock:(dispatch_block_t)block
{
    AMQPBlock *blockCommand = [[AMQPBlock alloc] initWithBlock:block semaphore:NULL];
    @synchronized(self) {
        [self.threadExitBlocks addObject:blockCommand];
    }
}

- (void)runThreadExitBlocks
{
    @synchronized(self) {
        for (AMQPBlock *block in [self.threadExitBlocks reverseObjectEnumerator]) {
            [block execute];
        }
        [self.threadExitBlocks removeAllObjects];
    }
}

- (void)cancel
{
    @synchronized(self) {
        if (self.isCancelled || self.isFinished) {
            return;
        }
        [super cancel];
    }
    
    // Running a timer will cause runMode:beforeDate to return and because the
    // thread is now cancelled the while loop will exit and the clean up will
    // occur.
    //
    // Order 0 is used so that this message will be processed before scheduled
    // blocks.
    [[NSRunLoop currentRunLoop] performSelector:@selector(description) target:self argument:nil order:0 modes:@[NSDefaultRunLoopMode]];
}

@end

@implementation AMQPBlock
{
    dispatch_block_t _block;
    dispatch_semaphore_t _semaphore;
}

- (instancetype)initWithBlock:(dispatch_block_t)block semaphore:(dispatch_semaphore_t)semaphore
{
    self = [super init];
    if (self) {
        _block = [block copy];
        _semaphore = semaphore;
    }
    return self;
}

- (void)execute
{
    _block();
    _block = nil;
    if (_semaphore) {
        dispatch_semaphore_signal(_semaphore);
        _semaphore = NULL;
    }
}

- (void)dealloc
{
    if (_semaphore) {
        dispatch_semaphore_signal(_semaphore);
        _semaphore = NULL;
    }
}

@end
