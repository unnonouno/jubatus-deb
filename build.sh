#!/bin/bash

# Directory Configuration
WORKDIR="${PWD}"
META_DIR="${WORKDIR}/metadata"
SOURCE_DIR="${WORKDIR}/source"
BUILD_DIR="${WORKDIR}/build"
DEST_DIR="${WORKDIR}/build_root"
PKG_DIR="${WORKDIR}/package"

# Version Configuration
. ./pkg_version

# -------------------------------
# @require_commands
# -------------------------------
@require_commands() {
        for CMD in "$@"; do
                if ! which "${CMD}" > /dev/null 2>&1; then
                        echo "ERROR: Cannot detect '$CMD' command"
                        return 1
                fi
        done
}

# -------------------------------
# download_url
# -------------------------------
download_url() {
        @require_commands wget

        URL="${1}"
        if [ ! -s "$(basename "${URL}")" ]; then
                wget "${URL}"
        fi
}

# -------------------------------
# do_download
# -------------------------------
do_download() {
        @require_commands mkdir rm git

        if [ -z "${FORCE}" -a -d "${SOURCE_DIR}" ]; then
                echo "${SOURCE_DIR} directory already exists; remove it and try again."
                return 1
        fi

        mkdir -p "${SOURCE_DIR}"
        pushd "${SOURCE_DIR}"

	# mpio
	download_url http://download.jubat.us/files/source/jubatus_mpio/jubatus_mpio-${MPIO_VER}.tar.gz

	# msgpack-rpc
	download_url http://download.jubat.us/files/source/jubatus_msgpack-rpc/jubatus_msgpack-rpc-${MSGPACK_RPC_VER}.tar.gz

	# jubatus
	download_url https://github.com/jubatus/jubatus/archive/${JUBATUS_VER}.tar.gz

        popd
        echo "----- Download Completed -----"
        return 0
}

do_build() {
	pushd "${SOURCE_DIR}"

	# mpio
	tar zxf jubatus_mpio-${MPIO_VER}.tar.gz
	mv jubatus_mpio-${MPIO_VER} jubatus-mpio-${MPIO_VER}
	mv jubatus_mpio-${MPIO_VER}.tar.gz jubatus-mpio_${MPIO_VER}.orig.tar.gz
	pushd jubatus-mpio-${MPIO_VER}
	cp -r ${META_DIR}/jubatus-mpio/debian .
	dpkg-buildpackage
	popd
	echo "Installing jubatus-mpio"
	sudo dpkg -i jubatus-mpio_${MPIO_VER}-1_amd64.deb
        sudo dpkg -i jubatus-mpio-dev_${MPIO_VER}-1_amd64.deb

	# msgpack-rpc
	tar zxf jubatus_msgpack-rpc-${MSGPACK_RPC_VER}.tar.gz
	mv jubatus_msgpack-rpc-${MSGPACK_RPC_VER} jubatus-msgpack-rpc-${MSGPACK_RPC_VER}
	mv jubatus_msgpack-rpc-${MSGPACK_RPC_VER}.tar.gz jubatus-msgpack-rpc_${MSGPACK_RPC_VER}.orig.tar.gz
	pushd jubatus-msgpack-rpc-${MSGPACK_RPC_VER}
	cp -r ${META_DIR}/jubatus-msgpack-rpc/debian .
	dpkg-buildpackage
	popd
	echo "Installing jubatus-msgpack-rpc"
	sudo dpkg -i jubatus-msgpack-rpc_${MSGPACK_RPC_VER}-1_amd64.deb
	sudo dpkg -i jubatus-msgpack-rpc-dev_${MSGPACK_RPC_VER}-1_amd64.deb

	# jubatus
	tar zxf ${JUBATUS_VER}.tar.gz
	mv ${JUBATUS_VER}.tar.gz jubatus_${JUBATUS_VER}.orig.tar.gz
	pushd jubatus-${JUBATUS_VER}
	cp -r ${META_DIR}/jubatus/debian .
	dpkg-buildpackage
	popd
	sudo dpkg -i jubatus_${JUBATUS_VER}-1_amd64.deb

	popd
	return 0
}

clean() {
	if apt-cache show jubatus; then
            sudo apt-get remove -y jubatus
        else
            echo 'jubatus is not installed'
        fi

        if apt-cache show jubatus-msgpack-rpc; then
            sudo apt-get remove -y jubatus-msgpack-rpc
        else
            echo 'jubatus-mspgack-rpc is not installed'
        fi

	if apt-cache show jubatus-msgpack-rpc-dev; then
	    sudo apt-get remove -y jubatus-msgpack-rpc-dev
	else
	    echo 'jubatus-msgpack-rpc-dev is not installed'
	fi

	if apt-cache show jubatus-mpio; then
            sudo apt-get remove -y jubatus-mpio
        else
            echo 'jubatus-mpio is not installed'
        fi

	if apt-cache show jubatus-mpio-dev; then
	    sudo apt-get remove -y jubatus-mpio-dev
	else
	    echo 'jubatus-mpio-dev is not installed'
	fi

        rm -rf source
}

clean
do_download
do_build

