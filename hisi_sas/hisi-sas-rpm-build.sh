#!/bin/bash -x

DRIVER="hisi_sas"
MAKE_PATH=`pwd`/build
HOST_KVER=`uname -r`
MOD_VERSION="5.3"
MOD_TARGETPATH=$DRIVER-$MOD_VERSION
MOD_DIR=/root/work/hisi-sas-update/drivers/scsi/hisi_sas
KDIR=/lib/modules/$HOST_KVER/build

function modify_os_name()
{
    local os=$2

    sed -i "/^%debug_package/d"          ~/.rpmmacros
    echo "%debug_package %{nil}"      >> ~/.rpmmacros
    if [ ! -f /etc/rpm/macros.dist ] ; then
        echo -e "# dist macros. \n\n"   >  /etc/rpm/macros.dist
        echo "%dist .el7"               >> /etc/rpm/macros.dist
    fi
    if [ "$os" == "sles15.1" ] ; then
        sed -i "/^%dist/ c\%dist .sles15.1"           /etc/rpm/macros.dist
    elif [ "$os" == "centos7.6" ] ; then
        sed -i "/^%dist/ c\%dist .centos7.6"          /etc/rpm/macros.dist
        sed -i "s/^%__check_files/#&/"                /usr/lib/rpm/macros
    elif [ "$os" == "kylin7.0" ] ; then
        sed -i "/^%dist/ c\%dist .neokylin7.0"        /etc/rpm/macros.dist
    elif [ "$os" == "euler2.0" ] ;then
        sed -i "/^%dist/ c\%dist .euler2.0"           /etc/rpm/macros.dist
        sed -i "s/^%__check_files/#&/"                /usr/lib/rpm/macros
    else
        echo "No need to modify the name by ostype"
    fi
}

function build_mod()
{
    cd $MOD_DIR
    make -C $KDIR M=$PWD clean
    make -C $KDIR M=$PWD
    xz -f *.ko
    find . -name "*.ko.xz" -exec cp -f {} $MAKE_PATH \;
}


function archive_targets()
{
    cd $MAKE_PATH

    rm -rf                $MOD_TARGETPATH
    mkdir -p              $MOD_TARGETPATH
    cp -rf *.ko.xz        $MOD_TARGETPATH

    tar -zcf  $MOD_TARGETPATH.tar.gz  $MOD_TARGETPATH
    rm -rf    $MOD_TARGETPATH

    rm -rf *.ko.xz
}

function archive_rpm()
{
    local os=$2
    local rpm_topdir=

    PackagePath=$MAKE_PATH/../bin
    if [ ! -d "$PackagePath" ] ; then
        mkdir -p "$PackagePath"
    fi

    if [ "$os" == "sles15.1" ] ; then
        rpm_topdir=/usr/src/packages
    elif [ "$os" == "centos7.6" ] ; then
        rpm_topdir=/root/rpmbuild
    fi

    rm -f $rpm_topdir/SOURCES/$MOD_TARGETPATH.tar.gz
    cp -f $MAKE_PATH/$MOD_TARGETPATH.tar.gz   $rpm_topdir/SOURCES
    cp -f $MAKE_PATH/../hisi_sas.aarch64.spec               $rpm_topdir/SPECS
    for file in $rpm_topdir/SPECS/*; do
        sed -i "s/4.14.0-115.el7a.aarch64/$HOST_KVER/" $file
    done 
    
    rpmbuild -bb $rpm_topdir/SPECS/hisi_sas.aarch64.spec --target aarch64 --define="version ${MOD_VERSION}"
    cp -f $rpm_topdir/RPMS/aarch64/hisi* $MAKE_PATH/../bin
    cd $MAKE_PATH
    rm -rf $MOD_TARGETPATH.tar.gz
}

## usage: ./this-script aarch64 centos7.6
function main()
{
    local os=$2
    if [ "$os" == "sles15.1" ] || [ "$os" == "centos7.6" ] ; then
	mkdir -p $MAKE_PATH
        #modify_os_name          $1  $os
        if [ $? -ne 0 ]; then
            return 1
        fi
        #modify_eth_version
        #if [ $? -ne 0 ]; then
        #    echo "modify eth version failed!"
        #    return 1
        #fi
        #build_prepare           $1  $os
        #if [ $? -ne 0 ]; then
        #    return 1
        #fi
        build_mod          $1  $os
        if [ $? -ne 0 ]; then
            echo "module compiled failed!"
            return 1
        fi
        archive_targets         $1  $os
        if [ $? -ne 0 ]; then
            return 1
        fi
        archive_rpm             $1  $os
        if [ $? -ne 0 ]; then
            echo "driver packaged failed"
            return 1
        fi
    else
        echo "System type error!"
    fi
}

main "$@"
exit $?
