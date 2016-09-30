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

### Issues
#### Trying to edit the sudoers file is not working in Ubuntu
Installing both packages in the same host creates and invalid sudoers file for opennebula.
Editing the file in centos is not a problem, but in ubuntu you cannot use the command ```sudo visudo -f ...``` due to the error in the file.
The solution is using the ```pkexec``` command so we can edit the file as the root user.  
From the man description of the pkexec
>pkexec allows an authorized user to execute PROGRAM as another user. If username is not specified, then the program will be executed as the administrative super user, root.

so, executing:
```
pkexec visudo -f /etc/sudoers.d/openenbula
```
will allow us to edit the openenbula file.
