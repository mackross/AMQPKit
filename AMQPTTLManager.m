//
//  CTXTTLManager.m
//  SMARTClassroom
//
//  Created by Pedro Gomes on 29/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import "CTXTTLManager.h"
#import <dispatch/source.h>

@implementation CTXTTLManager
{
    dispatch_queue_t    _lockQueue;
    NSMutableArray      *_objects;
    NSMutableArray      *_timers;
}

#pragma mark - Dealloc and Initialization

- (void)dealloc
{
    [self _performCleanup];
}

- (id)initWithDelegate:(id<CTXTTLManagerDelegate>)delegate
{
    if ((self = [self init])) {
        _delegate = delegate;
    }
    return self;
}
- (id)init
{
    if ((self = [super init])) {
        _lockQueue  = dispatch_queue_create("com.librabbitmq-objc.amqp.ttlmanager.lock", NULL);
        _objects    = [[NSMutableArray alloc] init];
        _timers     = [[NSMutableArray alloc] init];
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
        
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _lockQueue);
        [_timers addObject:[NSValue valueWithPointer:timer]];
        
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, ttl * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
        dispatch_source_set_event_handler(timer, ^{
            [self _cancelTimerForObject:object];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate ttlForObjectExpired:object];
            });
        });
        dispatch_resume(timer);
    });
}

- (BOOL)updateObject:(id)object ttl:(NSTimeInterval)ttl
{
    __block BOOL updated = NO;
    dispatch_sync(_lockQueue, ^{
        NSUInteger indexOfObject = [_objects indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            dispatch_source_t timer = [[_timers objectAtIndex:indexOfObject] pointerValue];
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, ttl * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
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
    dispatch_sync(_lockQueue, ^{ @autoreleasepool {
            NSArray *objectsToRemove = [NSArray arrayWithArray:_objects];
            [objectsToRemove enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                [self _cancelTimerForObject:object];
            }];
        }
    });
}

#pragma mark - Private Methods

- (void)_cancelTimerForObject:(id)object
{
    NSUInteger indexOfObject = [_objects indexOfObject:object];
    
    if (indexOfObject == NSNotFound) {
        return;
    }
    
    dispatch_source_t timer = [[_timers objectAtIndex:indexOfObject] pointerValue];
    dispatch_source_cancel(timer);
    
    [_objects removeObjectAtIndex:indexOfObject];
    [_timers removeObjectAtIndex:indexOfObject];
}

- (void)_performCleanup
{
    dispatch_sync(_lockQueue, ^{ @autoreleasepool {
        [_timers enumerateObjectsUsingBlock:^(NSValue *timer, NSUInteger idx, BOOL *stop) {
            dispatch_source_cancel([timer pointerValue]);
        }];
        [_timers removeAllObjects];
        [_objects removeAllObjects];
    }
    });
}

@end
