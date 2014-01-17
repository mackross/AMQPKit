//
//  AMQPTTLManager.m
//  librabbitmq-objc
//
//  Created by Pedro Gomes on 29/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "AMQPTTLManager.h"

@interface AMQPTTLManager()

@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSMutableArray *timers;

@end

@implementation AMQPTTLManager
{
    dispatch_queue_t    _lockQueue;
}

#pragma mark - Dealloc and Initialization

- (void)dealloc
{
    [self _performCleanup];
    
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_lockQueue);
#endif
}

- (id)initWithDelegate:(id<AMQPTTLManagerDelegate>)delegate
{
    if ((self = [self init])) {
        _delegate = delegate;
    }
    
    return self;
}

- (id)init
{
    if ((self = [super init])) {
        _objects    = [[NSMutableArray alloc] init];
        _timers     = [[NSMutableArray alloc] init];
        
        _lockQueue  = dispatch_queue_create("com.librabbitmq-objc.ttlmanager.lock", NULL);
        
#if !OS_OBJECT_USE_OBJC
        dispatch_retain(_lockQueue);
#endif
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)addObject:(id)object ttl:(NSTimeInterval)ttl
{
    dispatch_sync(_lockQueue, ^{
        if ([_objects indexOfObject:object] != NSNotFound) {
            return;
        }
        
        [_objects addObject:object];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:ttl target:self selector:@selector(onTick:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [_timers addObject:timer];
    });
}

- (void)onTick:(NSTimer *)timer
{
    dispatch_sync(_lockQueue, ^{
        NSUInteger indexOfTimer = [_timers indexOfObject:timer];
        if (indexOfTimer == NSNotFound) {
            return;
        }
        
        id object = [_objects objectAtIndex:indexOfTimer];
        
        [self _cancelTimerForObject:object];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate ttlForObjectExpired:object];
        });
    });
}

- (BOOL)updateObject:(id)object ttl:(NSTimeInterval)ttl
{
    __block BOOL updated = NO;
    dispatch_sync(_lockQueue, ^{
        NSUInteger indexOfObject = [_objects indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            NSTimer *timerToUpdate = [_timers objectAtIndex:indexOfObject];
            [timerToUpdate invalidate];

            NSTimer *replacementTimer = [NSTimer timerWithTimeInterval:ttl target:self selector:@selector(onTick:) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:replacementTimer forMode:NSRunLoopCommonModes];
            [_timers replaceObjectAtIndex:indexOfObject withObject:replacementTimer];

            updated = YES;
        }
    });
    return updated;
}

- (void)removeObject:(id)object
{
    dispatch_sync(_lockQueue, ^{
        [self _cancelTimerForObject:object];
    });
}

- (void)removeAllObjects
{
    dispatch_sync(_lockQueue, ^{
        NSArray *objectsToRemove = [NSArray arrayWithArray:_objects];
        __weak typeof(self) weakSelf = self;
        [objectsToRemove enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            [weakSelf _cancelTimerForObject:object];
        }];
    });
}

- (void)_cancelTimerForObject:(id)object
{
    NSUInteger indexOfObject = [_objects indexOfObject:object];
    if (indexOfObject == NSNotFound) {
        return;
    }
    
    NSTimer *timer = [_timers objectAtIndex:indexOfObject];
    [timer invalidate];
    [_timers removeObject:timer];
    [_objects removeObjectAtIndex:indexOfObject];
}

- (void)_performCleanup
{
    dispatch_sync(_lockQueue, ^{
        [_timers enumerateObjectsUsingBlock:^(NSTimer *timer, NSUInteger idx, BOOL *stop) {
            [timer invalidate];
        }];
        [_timers removeAllObjects];
        [_objects removeAllObjects];
    });
}

@end
