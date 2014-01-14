//
//  AMQPTTLManager.m
//  librabbitmq-objc
//
//  Created by Alberto De Bortoli on 14/01/2014.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import <dispatch/source.h>

#import "AMQPTTLManager.h"
#import "AMQPCommon.h"

@implementation AMQPTTLManager
{
    dispatch_queue_t    _lockQueue;
    NSMutableArray      *_objects;
    NSMutableArray      *_timers;
}

#pragma mark - Dealloc and Initialization

- (void)dealloc
{
    [self _performCleanup];
#if RABBITMQ_DISPATCH_RETAIN_RELEASE
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
#if RABBITMQ_DISPATCH_SOURCE_T_CAST_TO_CONST_VOID_STAR_ALLOWED
        [_timers addObject:[NSValue valueWithPointer:timer]];
#else
        [_timers addObject:[NSValue valueWithPointer:(__bridge const void *)(timer)]];
#endif
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, ttl * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
        dispatch_source_set_event_handler(timer, ^{
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate ttlForObjectExpired:object];
            });
        });
        dispatch_source_set_cancel_handler(timer, ^{
            NSUInteger indexOfObject = [_objects indexOfObject:object];
            if (indexOfObject != NSNotFound) {
                [_timers removeObjectAtIndex:indexOfObject];
                [_objects removeObject:object];
            }
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
        NSUInteger indexOfObject = [_objects indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            dispatch_source_t timer = [[_timers objectAtIndex:indexOfObject] pointerValue];
            dispatch_source_cancel(timer);
        }
    });
}

- (void)removeAllObjects
{
    dispatch_sync(_lockQueue, ^{
        NSArray *objectsToRemove = [_objects copy];
        [objectsToRemove enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            [self removeObject:object];
        }];
    });
}

#pragma mark - Private Methods

- (void)_performCleanup
{
    dispatch_sync(_lockQueue, ^{
        [_timers enumerateObjectsUsingBlock:^(NSValue *timer, NSUInteger idx, BOOL *stop) {
            dispatch_source_cancel([timer pointerValue]);
        }];
    });
}

@end
