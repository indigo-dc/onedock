Summary: ONEDock installation - EXPERIMENTAL. Please consider installing it by hand
Name: onedock-master
Version: 1.0
Release: 2
URL:     https://github.com/indigo-dc/onedock
License: Apache-2.0
Group: unknown
BuildRoot: %{_tmppath}/%{name}-root
Requires: xmlstarlet jq opennebula docker-engine = 1.9.1-1.el7.centos
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
sed -i.bak-onedock '/^[ \t]*TM_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{
s/\(arguments[ ]*=[ ]*\"[^\"]*\)\(".*$\)/\1,onedock\2/};
/^[ \t]*DATASTORE_MAD[ \t]*=[ \t]*\[/,/\][ \t]*$/{
s/\(arguments[ ]*=[ ]*\"[^\"]*\)\(".*$\)/\1,onedock\2/}' \
/etc/one/oned.conf

cat >> /etc/one/oned.conf << EOT
IM_MAD = [
      name       = "onedock",
      executable = "one_im_ssh",
      arguments  = "-r 3 -t 15 onedock" ]

VM_MAD = [
    name       = "onedock",
    executable = "one_vmm_exec",
    arguments  = "-t 15 -r 0 onedock",
    type       = "xml" ]

TM_MAD_CONF = [
    name = "onedock", ln_target = "SYSTEM", clone_target = "SYSTEM", shared = "yes"
]
EOT

echo "Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network,\
    /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount" >> /etc/sudoers.d/opennebula
sed -i.bak-onedock 's/^\(oneadmin ALL=.*\)$/\1, ONEDOCK/' /etc/sudoers.d/opennebula
sed -i.bkp -e "s/export LOCAL_SERVER=.*/export LOCAL_SERVER=$(hostname):5000/g" /var/lib/one/remotes/onedock.conf
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
