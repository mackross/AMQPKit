#!/usr/bin/env bash

echo "Will build armv7s library"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS6.0.sdk
./configure --host=arm-apple-darwin --enable-static \
  CC="$DEVROOT/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld 

make
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.armv7s

echo "Will build armv7 library"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS6.0.sdk
./configure --host=arm-apple-darwin --enable-static \
  CC="$DEVROOT/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld 

make
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.armv7

echo "Will build i386 library (simulator)"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneSimulator6.0.sdk
./configure --enable-static \
  CC="$DEVROOT/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/lib/gcc/i686-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld 

make
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.i386

echo "Will merge libs"
DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
$DEVROOT/usr/bin/lipo -arch armv7 librabbitmq.a.armv7 -arch armv7s librabbitmq.a.armv7s -arch i386 librabbitmq.a.i386 -create -output librabbitmq.a
file librabbitmq.a

