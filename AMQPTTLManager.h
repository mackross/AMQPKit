//
//  AMQPTTLManager.h
//  librabbitmq-objc
//
//  Created by Pedro Gomes on 29/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMQPTTLManagerDelegate <NSObject>

- (void)ttlForObjectExpired:(id)object;

@end

@interface AMQPTTLManager : NSObject

- (void)addObject:(id)object ttl:(NSTimeInterval)ttl;
- (BOOL)updateObject:(id)object ttl:(NSTimeInterval)ttl;

- (void)removeObject:(id)object;
- (void)removeAllObjects;

@property (nonatomic, weak) id<AMQPTTLManagerDelegate> delegate;

- (id)initWithDelegate:(id<AMQPTTLManagerDelegate>)delegate;

@end
