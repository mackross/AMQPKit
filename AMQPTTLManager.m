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
    [_timers enumerateObjectsUsingBlock:^(NSTimer *timer, NSUInteger idx, BOOL *stop) {
        [timer invalidate];
    }];
    [_timers removeAllObjects];
    [_objects removeAllObjects];
    
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
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(_lockQueue, ^{
        if ([weakSelf.objects indexOfObject:object] != NSNotFound) {
            return;
        }
        
        [weakSelf.objects addObject:object];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:ttl target:weakSelf selector:@selector(onTick:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [weakSelf.timers addObject:timer];
    });
}

- (void)onTick:(NSTimer *)timer
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(_lockQueue, ^{
        NSUInteger indexOfTimer = [weakSelf.timers indexOfObject:timer];
        if (indexOfTimer == NSNotFound) {
            return;
        }
        
        id object = [weakSelf.objects objectAtIndex:indexOfTimer];
        
        [weakSelf _cancelTimerForObject:object];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate ttlForObjectExpired:object];
        });
    });
}

- (BOOL)updateObject:(id)object ttl:(NSTimeInterval)ttl
{
    __block BOOL updated = NO;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(_lockQueue, ^{
        NSUInteger indexOfObject = [weakSelf.objects indexOfObject:object];
        if (indexOfObject != NSNotFound) {
            NSTimer *timerToUpdate = [weakSelf.timers objectAtIndex:indexOfObject];
            [timerToUpdate invalidate];

            NSTimer *replacementTimer = [NSTimer timerWithTimeInterval:ttl target:weakSelf selector:@selector(onTick:) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:replacementTimer forMode:NSRunLoopCommonModes];
            [weakSelf.timers replaceObjectAtIndex:indexOfObject withObject:replacementTimer];

            updated = YES;
        }
    });
    return updated;
}

- (void)removeObject:(id)object
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(_lockQueue, ^{
        [weakSelf _cancelTimerForObject:object];
    });
}

- (void)removeAllObjects
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(_lockQueue, ^{
        NSArray *objectsToRemove = [NSArray arrayWithArray:weakSelf.objects];
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
    [self.timers removeObject:timer];
    [self.objects removeObjectAtIndex:indexOfObject];
}

@end
