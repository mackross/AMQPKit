//
//  AMQPCommon.h
//  Objective-C wrapper for librabbitmq-c
//
//  Copyright 2009 Max Wolter. All rights reserved.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// Workaround for management of dispatch_retain() / dispatch_release() by ARC with iOS 6 / Mac OS X 10.8
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && (!defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0)) || \
    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && (!defined(__MAC_10_8) || __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8))

#define RABBITMQ_DISPATCH_RETAIN_RELEASE 1
#define RABBITMQ_DISPATCH_SOURCE_T_CAST_TO_CONST_VOID_STAR_ALLOWED 1

#endif
