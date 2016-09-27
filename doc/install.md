# Install
* [Ubuntu 14 instructions](https://indigo-dc.gitbooks.io/onedock/content/doc/install-ubuntu.html)
* [Centos 7 instructions](https://indigo-dc.gitbooks.io/onedock/content/doc/install-centos.html)

## Installing master and node in the same host
If you use the package installation and you want to install the master and the node on the same host you are going to create a conflict in the openenbula sudoers file.
To manually fix this conflict you have to edit the file
```
visudo -f /etc/sudoers.d/opennebula
```
and remove the duplicated entries:
```
oneadmin ALL=(ALL) NOPASSWD: ONE_MISC, ONE_NET, ONE_LVM, ONE_ISCSI, ONE_OVS, ONE_XEN, ONEDOCK, ONEDOCK
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount
```
after the fix:
```
oneadmin ALL=(ALL) NOPASSWD: ONE_MISC, ONE_NET, ONE_LVM, ONE_ISCSI, ONE_OVS, ONE_XEN, ONEDOCK
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount
```
To finish restart the opennebula service so the changes are registered:
```
sudo service opennebula restart
```
