Name: hisi_sas
Summary: Hisilicon hi16xx sas driver
Version:%{version}
Release: 1%dist
Source: %{name}-%{version}.tar.gz
Vendor: Huawei Corporation
License: GPL-2.0
ExclusiveOS: linux
Group: System Environment/Kernel
Provides: %{name}
URL:https://support.huawei.com
BuildRoot: %{_tmppath}/%{name}-%{version}-root
#BuildArch: aarch64
%define updates_version  4.14.0-115.el7a.aarch64
%define driver_path  drivers/scsi/hisi_sas
%define update_driver_path  /lib/modules/%{updates_version}/updates/%{driver_path} 
%define kernel_driver_path  /lib/modules/%{updates_version}/kernel/%{driver_path}


%description
This package contains Hisilicon hi16xx sas driver

%prep
%setup -q

%build

%install
echo "%Install running..."
rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/%{update_driver_path}
install -b -m -644 *.ko.xz ${RPM_BUILD_ROOT}/%{update_driver_path}/

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(644,root,root)
%{update_driver_path}/*.ko.xz

%pre
if [[ "$1" = "1" || "$1" = "2" ]] ; then  #1: install 2: update
    cd %{kernel_driver_path} &&
    for file in $(ls *.ko.xz) 
    do
        mv $file ${file}.bak 
    done
fi

%post
if [[ "$1" = "1" || "$1" = "2" ]] ; then  #1: install 2: update
    cp -rf  %{update_driver_path}/*.ko.xz %{kernel_driver_path}/
    /sbin/depmod -a            > /dev/null 2>&1 || true

    if which dracut >/dev/null 2>&1; then
        echo "Updating initramfs with dracut..."
        if dracut --force ; then
            echo "Successfully updated initramfs."
        else
            echo "Failed to update initramfs."
            echo "You must update your initramfs image for changes to take place."
            exit -1
        fi
    elif which mkinitrd >/dev/null 2>&1; then
        echo "Updating initrd with mkinitrd..."
        if mkinitrd; then
            echo "Successfully updated initrd."
        else
            echo "Failed to update initrd."
            echo "You must update your initrd image for changes to take place."
            exit -1
        fi
    else
        echo "Unable to determine utility to update initrd image."
        echo "You must update your initrd manually for changes to take place."
        exit -1
    fi
    echo "Finish updating driver. Please reboot system!!!" > /dev/stderr
fi

%preun

%postun
if [ "$1" = "0" ] ; then  #0: uninstall
    cd %{kernel_driver_path} &&
    rm -rf *.ko.xz
    for file in $(ls *.bak) 
    do
        mv $file $(echo $file | awk -F ".bak" '{print $1}') 
    done

    /sbin/depmod -a > /dev/null 2>&1 || true

    if which dracut >/dev/null 2>&1; then
        echo "Updating initramfs with dracut..."
        if dracut --force ; then
            echo "Successfully updated initramfs."
        else
            echo "Failed to update initramfs."
            echo "You must update your initramfs image for changes to take place."
            exit -1
        fi
    elif which mkinitrd >/dev/null 2>&1; then
        echo "Updating initrd with mkinitrd..."
        if mkinitrd; then
            echo "Successfully updated initrd."
        else
            echo "Failed to update initrd."
            echo "You must update your initrd image for changes to take place."
            exit -1
        fi
    else
        echo "Unable to determine utility to update initrd image."
        echo "You must update your initrd manually for changes to take place."
        exit -1
    fi
    
    echo "Finish removing driver. Please reboot system!!!" > /dev/stderr 
fi

%changelog
* Wed Sep 4 2019 xxxxxx <xxxxx@huawei.com>
- Version 5.3
- Release 1
