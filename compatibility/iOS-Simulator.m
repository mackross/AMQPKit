//
//  iOS-x86.m
//  librabbitmq-objc
//
//  Created by Stefan Ceriu on 02/04/2014.
//  Copyright (c) 2014 EF Education First. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_IPHONE_SIMULATOR

#include <sys/uio.h>
#include <sys/socket.h>

char * strerror$UNIX2003(int errnum)
{
    return strerror(errnum);
}

int close$UNIX2003(int fildes)
{
    return close(fildes);
}

int connect$UNIX2003(int socket, const struct sockaddr *address, socklen_t address_len)
{
    return connect(socket, address, address_len);
}

int fcntl$UNIX2003(int fildes, int cmd, ...)
{
    va_list args;
    va_start(args, cmd);
    int result = fcntl(fildes, cmd, args);
    va_end(args);
    
    return result;
}

int select$UNIX2003(int nfds, fd_set *restrict readfds, fd_set *restrict writefds, fd_set *restrict errorfds, struct timeval *restrict timeout)
{
    return select(nfds, readfds, writefds, errorfds, timeout);
}

ssize_t recv$UNIX2003(int socket, void *buffer, size_t length, int flags)
{
    return recv(socket, buffer, length, flags);
}

ssize_t send$UNIX2003(int socket, const void *buffer, size_t length, int flags)
{
    return send(socket, buffer, length, flags);
}

ssize_t writev$UNIX2003(int fildes, const struct iovec *iov, int iovcnt)
{
    return writev(fildes, iov, iovcnt);
}

#endif