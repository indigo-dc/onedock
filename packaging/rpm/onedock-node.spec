Summary: ONEDock installation - EXPERIMENTAL. Please consider installing it by hand
Name: onedock-node
Version: 1.2
Release: 2
URL:     https://github.com/indigo-dc/onedock
License: Apache-2.0
Group: unknown
BuildRoot: %{_tmppath}/%{name}-root
Requires: xmlstarlet jq opennebula-node-kvm docker-engine bridge-utils
BuildArch: noarch

%description
ONEDock is a set of extensions for OpenNebula to use containers as
 if they were virtual machines (VM).
 The concept of ONEDock is to configure Docker to act as an hypervisor.
 It behaves just as KVM does in the context of OpenNebula.

%post
grep -qF 'Cmnd_Alias ONEDOCK' /etc/sudoers.d/opennebula || echo "Cmnd_Alias ONEDOCK = \
    /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount" >> /etc/sudoers.d/opennebula
grep -q 'oneadmin ALL=.*, ONEDOCK' /etc/sudoers.d/opennebula || sed -i.bak-onedock 's/^\(oneadmin ALL=.*\)$/\1, ONEDOCK/' /etc/sudoers.d/opennebula
usermod -aG docker oneadmin
touch /var/log/onedock.log && chown oneadmin:oneadmin /var/log/onedock.log

%files

%changelog
