//
//  CTXTTLManager.h
//  SMARTClassroom
//
//  Created by Pedro Gomes on 29/11/2012.
//  Copyright (c) 2012 EF Education First. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol CTXTTLManagerDelegate <NSObject>

- (void)ttlForObjectExpired:(id)object;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface CTXTTLManager : NSObject

//- (BOOL)containsObject:(id)object;
- (void)addObject:(id)object ttl:(NSTimeInterval)ttl;
- (BOOL)updateObject:(id)object ttl:(NSTimeInterval)ttl;

- (void)removeObject:(id)object;
- (void)removeAllObjects;

@property (nonatomic, weak) id<CTXTTLManagerDelegate> delegate;

- (id)initWithDelegate:(id<CTXTTLManagerDelegate>)delegate;

@end
