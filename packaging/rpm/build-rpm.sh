#!/bin/bash
set -e
NODE=master
VERSION=1.0-2
APP=onedock
BASE_FOLDER=.

FILELIST="vmm im datastore tm onedock.sh onedock.conf docker-manage-network"

function copy_files {
    mkdir -p ./dist/$BUILD_PKG/var/lib/one/remotes/
    for f in $FILELIST; do
        cp -r $BASE_FOLDER/$f ./dist/$BUILD_PKG/var/lib/one/remotes/
    done
}

while [ $# -gt 0 ]; do
    case $1 in
        -f)	BASE_FOLDER=$2
            shift
            shift;;
        *)	echo "unexpected parameter $1" >&2
            exit 1;;

esac
done
rm -rf dist
BUILD_PKG=${APP}-master-${VERSION}
mkdir -p ./dist/$BUILD_PKG/
copy_files
cd ./dist
tar cfz ${BUILD_PKG}.tar.gz ${BUILD_PKG}
cd -
rpmbuild --bb onedock-master.spec --clean --define \
"_sourcedir $PWD/dist/" --define "_topdir $PWD/dist/"
rpmbuild --bb onedock-node.spec --define "_topdir $PWD/dist/"

#BUILD_PKG=${APP}_${VERSION}_node
#mkdir -p ./dist/$BUILD_PKG/
#cp -r node/DEBIAN/ ./dist/$BUILD_PKG/
#dpkg-deb --build ./dist/$BUILD_PKG
