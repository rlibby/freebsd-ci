#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

TARGET=riscv
TARGET_ARCH=riscv64

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
ARTIFACT_DEST=${WORKSPACE}/artifact/${ARTIFACT_SUBDIR}
rm -fr ${WORKSPACE}/artifact
mkdir -p ${ARTIFACT_DEST}

rm -fr riscv-pk
git config --global http.proxy ${BUILDER_HTTP_PROXY}
git clone --depth=1 --single-branch https://github.com/freebsd-riscv/riscv-pk
cd riscv-pk
git rev-parse HEAD

cd ${WORKSPACE}
rm -f kernel.xz kernel
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/kernel.xz
xz -d kernel.xz

mkdir riscv-pk/build/
cd riscv-pk/build/

export CC=riscv64-unknown-freebsd11.1-gcc
export CFLAGS="-nostdlib"
export RANLIB=riscv64-unknown-freebsd11.1-ranlib
export READELF=riscv64-unknown-freebsd11.1-readelf
export OBJCOPY=riscv64-unknown-freebsd11.1-objcopy
../configure --enable-logo --host=riscv64-unknown-freebsd11.1 --with-payload=${WORKSPACE}/kernel
gmake

xz bbl
mv bbl.xz ${ARTIFACT_DEST}

cd ${WORKSPACE}
echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
