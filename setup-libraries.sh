#!/bin/bash
set -e -u

UNAME=$(uname -s);

MISSING_DEPS=""

function ensure_dep {
    if [[ ! `which $1` ]]; then
        MISSING_DEPS="$MISSING_DEPS $1"
    fi
}

ensure_dep aclocal
ensure_dep cmake
ensure_dep automake
ensure_dep autoconf
ensure_dep pkg-config
if [ ${UNAME} = 'Darwin' ]; then
    ensure_dep makedepend
    if [[ ! `which libtool` ]] && [[ ! `which glibtool` ]]; then
        MISSING_DEPS="$MISSING_DEPS libtool"
    fi
elif [ ${UNAME} = 'Linux' ]; then
    ensure_dep libtool
    ensure_dep gccmakedep
fi

if [[ $MISSING_DEPS != "" ]]; then
    if [ ${UNAME} = 'Darwin' ]; then
        echo "Missing build deps: ${MISSING_DEPS}"
        echo 'Please run "brew install autoconf automake libtool makedepend cmake pkg-config"'
        echo 'and then re-run ./setup-libraries.sh'
    elif [ ${UNAME} = 'Linux' ]; then
        echo "Missing build deps: ${MISSING_DEPS}"
        echo 'Please run "sudo apt-get install git build-essential zlib1g-dev automake libtool xutils-dev make cmake pkg-config libxi-dev libglu1-mesa-dev x11proto-randr-dev x11proto-xext-dev libxrandr-dev x11proto-xf86vidmode-dev libxxf86vm-dev libxcursor-dev"'
        echo 'and then re-run ./setup-libraries.sh'
    fi
    exit 1
fi

# bootstrap node install
if [[ ! -d ~/.nvm ]]; then
    git clone --depth 1 https://github.com/creationix/nvm.git ~/.nvm
fi
set +u
source ~/.nvm/nvm.sh
nvm install 0.10
set -u

NODE=$(which node)
NPM=$(which npm)

MP_HASH="e82e6c00ea5a0cda147e4c121a3c7751cae69ff8"
DIR_HASH=$(echo `pwd` | git hash-object --stdin)
if [ ! -d 'mapnik-packaging/' ]; then
  git clone https://github.com/mapnik/mapnik-packaging.git
fi

cd mapnik-packaging
git fetch
git checkout ${MP_HASH}
cd ./osx/

export CXX11=true

if [ ${UNAME} = 'Darwin' ]; then

if [ ! -z "${TRAVIS:-}" ]; then
    if aws s3 cp s3://${AWS_S3_BUCKET}/dependencies/build-cpp11-libcpp-osx_${MP_HASH}_${DIR_HASH}.tar.gz ./out/ ; then
        if aws s3 cp s3://${AWS_S3_BUCKET}/dependencies/build-cpp11-libcpp-ios_${MP_HASH}_${DIR_HASH}.tar.gz ./out/ ; then
            rm -rf out/build-cpp11-libcpp-x86_64-macosx
            rm -rf out/build-cpp11-libcpp-universal
            tar -xzf out/build-cpp11-libcpp-osx_${MP_HASH}_${DIR_HASH}.tar.gz
            tar -xzf out/build-cpp11-libcpp-ios_${MP_HASH}_${DIR_HASH}.tar.gz
        fi
    fi
fi

if test -z "${TRAVIS:-}" || ! test -d out/build-cpp11-libcpp-universal; then

source iPhoneOS.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libcpp-armv7-iphoneos/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-armv7-iphoneos/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    echo '     ...done'

source iPhoneOSs.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libcpp-armv7s-iphoneoss/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-armv7s-iphoneoss/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    echo '     ...done'

source iPhoneOS64.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libcpp-arm64-iphoneos64/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-arm64-iphoneos64/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    echo '     ...done'

source iPhoneSimulator.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libcpp-i386-iphonesimulator/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-i386-iphonesimulator/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    echo '     ...done'

source iPhoneSimulator64.sh
export LIBUV_VERSION=0.10.28
   if [ ! -f out/build-cpp11-libcpp-x86_64-iphonesimulator/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
   if [ ! -f out/build-cpp11-libcpp-x86_64-iphonesimulator/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
   echo '     ...done'

source MacOSX.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libcpp-x86_64-macosx/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-x86_64-macosx/lib/libglfw3.a ] ; then ./scripts/build_glfw.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-x86_64-macosx/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-x86_64-macosx/lib/libssl.a ] ; then ./scripts/build_openssl.sh ; fi
    if [ ! -f out/build-cpp11-libcpp-x86_64-macosx/lib/libcurl.a ] ; then ./scripts/build_curl.sh ; fi
    if [ ! -d out/build-cpp11-libcpp-x86_64-macosx/include/boost ] ; then ./scripts/build_boost.sh `pwd`/../../src/ `pwd`/../../include/ `pwd`/../../linux/ `pwd`/../../common/ ; fi
    echo '     ...done'

# setup iOS universal libs
./scripts/make_universal.sh

if [ ! -z "${TRAVIS:-}" ] && [ ! -z "${AWS_ACCESS_KEY_ID}" ] && [ ! -z "${AWS_SECRET_ACCESS_KEY}" ] ; then
    tar -zcf out/build-cpp11-libcpp-ios_${MP_HASH}_${DIR_HASH}.tar.gz out/build-cpp11-libcpp-universal
    aws s3 cp --acl public-read out/build-cpp11-libcpp-ios_${MP_HASH}_${DIR_HASH}.tar.gz s3://${AWS_S3_BUCKET}/dependencies/
    tar -zcf out/build-cpp11-libcpp-osx_${MP_HASH}_${DIR_HASH}.tar.gz out/build-cpp11-libcpp-x86_64-macosx
    aws s3 cp --acl public-read out/build-cpp11-libcpp-osx_${MP_HASH}_${DIR_HASH}.tar.gz s3://${AWS_S3_BUCKET}/dependencies/
fi

fi

cd ../../

# default to OS X build product symlinking
./mapnik-packaging/osx/darwin_configure.sh osx

elif [ ${UNAME} = 'Linux' ]; then

if [ ! -z "${TRAVIS:-}" ]; then
    if aws s3 cp s3://${AWS_S3_BUCKET}/dependencies/build-cpp11-libstdcpp-gcc-x86_64-linux_${MP_HASH}_${DIR_HASH}.tar.gz ./out/ ; then
        rm -rf out/build-cpp11-libstdcpp-gcc-x86_64-linux
        tar -xzf out/build-cpp11-libstdcpp-gcc-x86_64-linux_${MP_HASH}_${DIR_HASH}.tar.gz
    fi
fi

source Linux.sh
export LIBUV_VERSION=0.10.28
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libglfw3.a ] ; then ./scripts/build_glfw.sh ; fi
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libpng.a ] ; then ./scripts/build_png.sh ; fi
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libuv.a ] ; then ./scripts/build_libuv.sh ; fi
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libssl.a ] ; then ./scripts/build_openssl.sh ; fi
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libcurl.a ] ; then ./scripts/build_curl.sh ; fi
    if [ ! -f out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/libboost_regex.a ] ; then ./scripts/build_boost.sh --with-regex ; fi

if [ ! -z "${TRAVIS:-}" ] && [ ! -z "${AWS_ACCESS_KEY_ID}" ] && [ ! -z "${AWS_SECRET_ACCESS_KEY}" ] ; then
    if ! tar --compare -zf out/build-cpp11-libstdcpp-gcc-x86_64-linux.tar.gz ; then
        tar -zcf out/build-cpp11-libstdcpp-gcc-x86_64-linux_${MP_HASH}_${DIR_HASH}.tar.gz out/build-cpp11-libstdcpp-gcc-x86_64-linux
        aws s3 cp --acl public-read out/build-cpp11-libstdcpp-gcc-x86_64-linux_${MP_HASH}_${DIR_HASH}.tar.gz s3://${AWS_S3_BUCKET}/dependencies/
    fi
fi

cd ../../
./configure \
--pkg-config-root=`pwd`/mapnik-packaging/osx/out/build-cpp11-libstdcpp-gcc-x86_64-linux/lib/pkgconfig \
--boost=`pwd`/mapnik-packaging/osx/out/build-cpp11-libstdcpp-gcc-x86_64-linux \
--npm=$NPM \
--node=$NODE
fi
