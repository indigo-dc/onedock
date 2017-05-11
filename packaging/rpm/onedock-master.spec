Summary: ONEDock installation - EXPERIMENTAL. Please consider installing it by hand
Name: onedock-master
Version: 1.1
Release: 1
URL:     https://github.com/indigo-dc/onedock
License: Apache-2.0
Group: unknown
BuildRoot: %{_tmppath}/%{name}-root
Requires: xmlstarlet jq opennebula docker-engine bridge-utils
Source0: onedock-master-%{version}.tar.gz
BuildArch: noarch

%description
ONEDock is a set of extensions for OpenNebula to use containers as
 if they were virtual machines (VM).
 The concept of ONEDock is to configure Docker to act as an hypervisor.
 It behaves just as KVM does in the context of OpenNebula.

%prep
%setup
DESTFOLDER=/var/lib/one/remotes/

%build

%install
DESTFOLDER=/var/lib/one/remotes/
FILELIST="vmm im datastore tm onedock.sh onedock.conf docker-manage-network"
rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/${DESTFOLDER}
for f in $FILELIST; do
    cp -r --remove-destination var/lib/one/remotes/$f ${RPM_BUILD_ROOT}/${DESTFOLDER}
done

%post
ONE_VER=$(yum info opennebula | grep 'Vers*' | awk '{split($3,onev,"."); print onev[1]}')
set -e

function configure_one4 {
cat >> /etc/one/oned.conf << EOT
#*******************************************************************************
# ONEDOCK configuration
#*******************************************************************************

IM_MAD = [
    name       = "onedock",
    executable = "one_im_ssh",
    arguments  = "-r 3 -t 15 onedock"
]

VM_MAD = [
    name       = "onedock",
    executable = "one_vmm_exec",
    arguments  = "-t 15 -r 0 onedock",
    type       = "xml"
]

TM_MAD_CONF = [
    name = "onedock", ln_target = "SYSTEM", clone_target = "SYSTEM", shared = "yes"
]
EOT

sed -i.bak-onedock '/^[ \t]*TM_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{
s/\(arguments[ ]*=[ ]*\"[^\"]*\)\(".*$\)/\1,onedock\2/};
/^[ \t]*DATASTORE_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{
s/\(arguments[ ]*=[ ]*\"[^\"]*\)\(".*$\)/\1,onedock\2/}' \
/etc/one/oned.conf
}

function configure_one5 {
cat >> /etc/one/oned.conf << EOT
#*******************************************************************************
# ONEDOCK configuration
#*******************************************************************************

IM_MAD = [
    NAME          = "onedock",
    SUNSTONE_NAME = "ONEDock",
    EXECUTABLE    = "one_im_ssh",
    ARGUMENTS     = "-r 3 -t 15 onedock"
]

VM_MAD = [
    NAME           = "onedock",
    SUNSTONE_NAME  = "ONEDock",
    EXECUTABLE     = "one_vmm_exec",
    ARGUMENTS      = "-t 15 -r 0 onedock",
    TYPE           = "xml",
    KEEP_SNAPSHOTS = "no",
    IMPORTED_VMS_ACTIONS = "terminate, terminate-hard, hold, release, delete, reboot, reboot-hard"
]

TM_MAD_CONF = [
    NAME = "onedock", LN_TARGET = "SELF", CLONE_TARGET = "SELF", SHARED = "YES", DS_MIGRATE = "NO"
]

DS_MAD_CONF = [
    NAME = "onedock", REQUIRED_ATTRS = "", PERSISTENT_ONLY = "NO"
]
EOT

sed -i.bak '/^[ \t]*TM_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{s/\(ARGUMENTS[ ]*=[ ]*\"[^\"]*\)\(".*$\)/\1,onedock\2/};/^[ \t]*DATASTORE_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{s/\(ARGUMENTS[ ]*=[ ]*\"[^\"]*-d [^\"]*\)\( -s [^\"]*\)\(".*$\)/\1,onedock\2,onedock\3/}' /etc/one/oned.conf
}

if [ $ONE_VER -eq 5 ]; then
    configure_one5
else
    configure_one4
fi

sed -i.bkp -e "s/export LOCAL_SERVER=.*/export LOCAL_SERVER=$(hostname):5000/g" /var/lib/one/remotes/onedock.conf
sed -i.bak-onedock 's/^\(oneadmin ALL=.*\)$/\1, ONEDOCK/' /etc/sudoers.d/opennebula
echo "Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount" >> /etc/sudoers.d/opennebula
usermod -aG docker oneadmin
touch /var/log/onedock.log && chown oneadmin:oneadmin /var/log/onedock.log
chown -R oneadmin:oneadmin /var/lib/one/remotes
chmod -x /var/lib/one/remotes/im/onedock.d/collectd-client.rb

%clean
DESTFOLDER=/var/lib/one/remotes/
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%attr(755,root,root) /var/lib/one/remotes/*

%changelog
