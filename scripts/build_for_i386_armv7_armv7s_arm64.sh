#!/usr/bin/env bash

autoreconf -i

echo "Will build i386 rabbitmq-c library for iOS Simulator"
make clean

./configure --host=i386-apple-darwin --with-ssl=no --enable-static \
  CC="/usr/bin/clang -arch i386" \
  LD=$DEVROOT/usr/bin/ld

make
lipo -info librabbitmq/.libs/librabbitmq.a
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.i386

echo "Will build armv7 rabbitmq-c library for iOS Devices"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS7.1.sdk
./configure --host=armv7-apple-darwin --enable-static --with-ssl=no \
  CC="/usr/bin/clang -arch armv7" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld

make
lipo -info librabbitmq/.libs/librabbitmq.a
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.armv7

echo "Will build armv7s rabbitmq-c library for iOS Devices"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS7.1.sdk
./configure --host=armv7s-apple-darwin --enable-static --with-ssl=no \
  CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -arch armv7s" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld

make
lipo -info librabbitmq/.libs/librabbitmq.a
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.armv7s

echo "Will build arm64 rabbitmq-c library for iOS Devices"
make clean

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS7.1.sdk
./configure --host=aarch64-apple-darwin --enable-static --with-ssl=no \
  CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -arch arm64" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  LD=$DEVROOT/usr/bin/ld

make
lipo -info librabbitmq/.libs/librabbitmq.a
mv librabbitmq/.libs/librabbitmq.a librabbitmq.a.arm64

echo "Will merge libs"

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
$DEVROOT/usr/bin/lipo -arch armv7 librabbitmq.a.armv7 -arch armv7s librabbitmq.a.armv7s -arch i386 librabbitmq.a.i386 -arch arm64 librabbitmq.a.arm64 -create -output librabbitmq.a
file librabbitmq.a