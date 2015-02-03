//
//  AMQP.h
//  AMQP
//
//  Created by Andrew Mackenzie-Ross on 3/02/2015.
//  Copyright (c) 2015 librabbitmq. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for AMQP.
FOUNDATION_EXPORT double AMQPVersionNumber;

//! Project version string for AMQP.
FOUNDATION_EXPORT const unsigned char AMQPVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AMQP/PublicHeader.h>

#import <AMQP/AMQPChannel.h>
#import <AMQP/AMQPConnection.h>
#import <AMQP/AMQPConsumer.h>
#import <AMQP/AMQPConsumerThread.h>
#import <AMQP/AMQPExchange.h>
#import <AMQP/AMQPExchange+Additions.h>
#import <AMQP/AMQPMessage.h>
#import <AMQP/AMQPQueue.h>
#import <AMQP/AMQPTTLManager.h>

