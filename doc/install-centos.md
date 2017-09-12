# Centos 7
## Front-end node
### Prerrequisites
#### OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official [OpenNebula documentation](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_centos7_kvm.html).

If you have issues with the _nfs_ service enable first the _rcpbind_ service and try again. To enable _rcpbind_ use the following commands:

```bash
$ systemctl enable rpcbind
$ systemctl start rpcbind
```

#### Docker
Then you have to install Docker, according to the official [Docker documentation](https://docs.docker.com/engine/installation/linux/centos/).

**Warning**
> We recommend using docker version 1.9.
> If you use docker engine versions greater than 1.9, we can not ensure that OneDock works correctly. If you have doubts about installing an scpecific version of docker, please check the installation scripts in this repository: _install/centos/install-docker_

You need to install a Docker Registry v2.0 that is usable from all the nodes. Its name must be included in the variable `LOCAL_SERVER` in the file `/var/lib/one/remotes/onedock.conf`.

_REMEMBER_ to install the certificates of your Docker registry in the proper directories. The most easy way to install the certificate is to copy it into the folder `/etc/docker/certs.d/$HOSTNAME:5000/`. But you should copy it for the whole system in case that you want to use other commands (e.g. curl).

In case of CentOS 7, you can use the following code:

```bash
$ mkdir -p /etc/docker/certs.d/$HOSTNAME:5000/
$ cp /var/lib/docker-registry/certs/domain.crt /etc/docker/certs.d/$HOSTNAME\:5000/
$ cp /var/lib/docker-registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
$ update-ca-trust extract
$ service docker restart
```

#### Required packages
Now install the required packages: jq, xmlstarlet

```bash
$ yum -y install jq xmlstarlet
```

### Installation of ONEDock and activating it in ONE
#### From package
You must have the epel repository enabled:
```sh
$ yum install epel-release
```

Then you have to download the required package:
```
$ wget http://repo.indigo-datacloud.eu/repository/indigo/2/centos7/x86_64/updates/onedock-master-1.2-1.noarch.rpm -O onedock-master
```

And install its dependencies and the main package:
```
$ yum install jq xmlstarlet
$ rpm -i onedock-master --replacefiles
```

Finally restart the opennebula service:
```
$ sudo service opennebula restart
```

#### Manually
Once OpenNebula, Docker, a Docker Registry and the required packages have been installed, you can install ONEDock as follows (as root user):

```bash
$ cd /tmp/
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock
$ ./setup_files.sh
```

ONEDock will be installed. Then you should adjust the variables in ```/var/lib/one/remotes/onedock.conf``` according to your deployment. In particular:

* LOCAL_SERVER points to the local docker registry
* DATASTORE_DATA_PATH points to the folder in which the images in the docker registry are stored

In order to activate ONEDock in ONE, you just need to update the /etc/one/oned.conf file.

```bash
$ cat >> /etc/one/oned.conf << EOF
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
EOF
```

Then you must add onedock to be available as transfer manager and datastore. Please locate the proper lines in /etc/one/oned.conf file and append the ```onedock``` keyword. In the default installation, the result will be similar to the next one:

```bash
TM_MAD = [
    executable = "one_tm",
    arguments = "-t 15 -d dummy,lvm,shared,fs_lvm,qcow2,ssh,vmfs,ceph,dev,onedock"
]

DATASTORE_MAD = [
    executable = "one_datastore",
    arguments  = "-t 15 -d dummy,fs,vmfs,lvm,ceph,dev,onedock"
]
```

## Computing nodes
### Installation of OpenNebula, Docker and the required packages
#### OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official [OpenNebula documentation](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_centos7_kvm.html).

#### Docker
You have to install Docker, according to the official [Docker documentation](https://docs.docker.com/engine/installation/linux/centos/).

**Warning**
> We recommend using docker version 1.9.
> If you use docker engine versions greater than 1.9, we can not ensure that OneDock works correctly. If you have doubts about installing an scpecific version of docker, please check the installation scripts in this repository: _install/centos/install-docker_

_REMEMBER_ to install the certificates of your Docker registry (from the frontend) in the proper directories (of the nodes). In case of CentOS 7, you can use the following code:

```bash
$ scp oneadmin@FRONT_END_IP:/var/lib/docker-registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
$ update-ca-trust extract
$ service docker restart
```

#### Required packages
Now install the required packages: jq, xmlstarlet

```bash
$ yum -y install jq xmlstarlet
```
### Installation of ONEDock and activating it in ONE
#### From package

You must have the epel repository enabled:

```sh
$ yum install epel-release
```

Then you have to enable the INDIGO - DataCloud packages repositories. See full instructions
[here](https://indigo-dc.gitbooks.io/indigo-datacloud-releases/content/generic_installation_and_configuration_guide_1.html#id4). Briefly you have to download the repo file from [INDIGO SW Repository](http://repo.indigo-datacloud.eu/repos/1/indigo1.repo) in your /etc/yum.repos.d folder.

```sh
$ cd /etc/yum.repos.d
$ wget http://repo.indigo-datacloud.eu/repos/2/indigo2.repo
```

And then install the GPG key for the INDIGO repository:

```sh
$ rpm --import http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc
```

Finally install the Onedock package.

```sh
$ yum install onedock-node
```

#### Manually
You need to update the file ```/etc/sudoers.d/opennebula``` to add the file that will configure the network. You need to add the line

```bash
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd, /sbin/losetup, /bin/mount
```

And to activate this alias appending the alias in the following line

```bash
oneadmin ALL=(ALL) NOPASSWD: ONE_MISC, ONE_NET, ONE_LVM, ONE_ISCSI, ONE_OVS, ONE_XEN, ONEDOCK
```

Also you need to add the ```oneadmin``` user to the ```docker``` group, in order to be able to run docker containers.

```bash
$ usermod -aG docker oneadmin
```

Finally you need to create the onedock log file and give permission to the oneadmin user
```bash
$ touch /var/log/onedock.log && chown oneadmin:oneadmin /var/log/onedock.log
```

## Issues
Most of the issues come from an incorrect configuration of OpenNebula or the docker registry. The main way to find what is causing the issue is checking the log files.

The log file for ONEDock can be found in `/var/log/onedock.log`.
The log of the OpenNebula daemon is located in `/var/log/one/oned.log`.

##### Job for nfs-server.service failed because the control process exited with error code
This error can happen during the OpenNebula installation. If you have issues with the _nfs_ service enable first the _rcpbind_ service and try again. To enable _rcpbind_ use the following commands:

```bash
$ systemctl enable rpcbind
$ systemctl start rpcbind
```
##### Failed to connect socket to '/var/run/libvirt/libvirt-sock': No such file or directory
If the frontend fails to add a new host and you see this error in the `/var/log/one/oned.log` file, make sure that you have the libvirt daemon running in the node that you want to add. To enable the daemon execute:
```bash
$ /usr/sbin/libvirtd -d
```
##### Can't connect to the NFS server - mount.nfs: Connection timed out
Most of the times this means that the firewall is blocking our NFS server.
A nice tutorial to set up a nfs server and connect a client can be found [here](http://www.unixmen.com/setting-nfs-server-client-centos-7/).
