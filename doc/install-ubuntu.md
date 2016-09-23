# Ubuntu 14.04
## Front-end node
### Prerrequisites
#### OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official [OpenNebula documentation](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_ubuntu_kvm.html).

#### Docker
Then you have to install Docker, according to the official [Docker documentation](https://docs.docker.com/engine/installation/ubuntulinux/).

**Warning**
> We recommend using docker version 1.9.
> If you use docker engine versions greater than 1.9, we can not ensure that OneDock works correctly. If you have doubts about installing an scpecific version of docker, please check the installation scripts in this repository: _install/ubuntu/install-docker_

You need to install a Docker Registry v2.0 that is usable from all the nodes. Its name must be included in the variable ```LOCAL_SERVER``` in the file ```/var/lib/one/remotes/onedock.conf```.

_REMEMBER_ to install the certificates of your Docker registry in the proper directories. The most easy way to install the certificate is to copy it into the folder ```/etc/docker/certs.d/$HOSTNAME:5000/```. But you should copy it for the whole system in case that you want to use other commands (e.g. curl).

For the case of ubuntu, you can use a code like this:

```bash
$ mkdir -p /etc/docker/certs.d/onedockdemo:5000/
$ cp domain.crt /usr/local/share/ca-certificates/
$ cp domain.crt /etc/docker/certs.d/onedockdemo:5000/
$ update-ca-certificates
```

#### Required packages
Now install the required packages: jq, xmlstarlet, qemu-utils and bridge-utils.

```bash
$ apt-get -y install jq xmlstarlet qemu-utils bridge-utils.
```

### Installation of ONEDock and activating it in ONE
#### From package
You have to enable the INDIGO - DataCloud packages repositories. See full instructions
[here](https://indigo-dc.gitbooks.io/indigo-datacloud-releases/content/generic_installation_and_configuration_guide_1.html#id4). Briefly you have to download the list file from [INDIGO SW Repository](http://repo.indigo-datacloud.eu/repos/1/indigo1-ubuntu14_04.list) in your /etc/apt/sources.list.d folder.

```bash
$ cd /etc/apt/sources.list.d
$ wget http://repo.indigo-datacloud.eu/repos/1/indigo1-ubuntu14_04.list
```

And then install the GPG key for INDIGO the repository:

```bash
$ wget -q -O - http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc | sudo apt-key add -
```

Install the Onedock package.

```bash
$ apt update
$ apt install onedock-master
```
Finally restart opennebula so the changes applied by the onedock installation are applied:
```bash
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
### Prerrequisites
#### OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official OpenNebula documentation (e.g. [for Ubuntu](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_ubuntu_kvm.html)).

#### Docker
Then you have to install Docker, according to the official documentation (e.g. for [Ubuntu](https://docs.docker.com/engine/installation/ubuntulinux/)).

**Warning**
> We recommend using docker version 1.9.
> If you use docker engine versions greater than 1.9, we can not ensure that OneDock works correctly. If you have doubts about installing an scpecific version of docker, please check the installation scripts in this repository: _install/ubuntu/install-docker_

_REMEMBER_ to install the certificates of your Docker registry in the proper directories. The most easy way to install the certificate is to copy it into the folder ```/etc/docker/certs.d/$HOSTNAME:5000/```. But you should copy it for the whole system in case that you want to use other commands (e.g. curl).

For the case of ubuntu, you can use a code like this:

```bash
$ mkdir -p /etc/docker/certs.d/onedockdemo:5000/
$ cp domain.crt /usr/local/share/ca-certificates/
$ cp domain.crt /etc/docker/certs.d/onedockdemo:5000/
$ update-ca-certificates
```
#### Required packages
Now install the required packages: jq, xmlstarlet, qemu-utils and bridge-utils.

```bash
$ apt-get -y install jq xmlstarlet qemu-utils bridge-utils.
```

### Installation of ONEDock and activating it in ONE
#### From package
You have to enable the INDIGO - DataCloud packages repositories. See full instructions
[here](https://indigo-dc.gitbooks.io/indigo-datacloud-releases/content/generic_installation_and_configuration_guide_1.html#id4). Briefly you have to download the list file from [INDIGO SW Repository](http://repo.indigo-datacloud.eu/repos/1/indigo1-ubuntu14_04.list) in your /etc/apt/sources.list.d folder.

```bash
$ cd /etc/apt/sources.list.d
$ wget http://repo.indigo-datacloud.eu/repos/1/indigo1-ubuntu14_04.list
```

And then install the GPG key for INDIGO the repository:

```bash
$ wget -q -O - http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc | sudo apt-key add -
```

Install the Onedock package.

```bash
$ apt update
$ apt install onedock-node
```
Finally restart opennebula so the changes applied by the onedock installation are applied:
```bash
$ sudo service opennebula restart
```

#### Manually
If you prefer you can try yo install onedock manually using following code.  
This step is very dependent from your installation and you should check out what are you doing:

```bash
# The oneadmin user should be able to run docker
$ usermod -aG docker oneadmin

# Starting the nbd module and setting it persistent
$ modprobe nbd max_part=16
$ echo "nbd" >> /etc/modules

$ cat > /etc/modprobe.d/nbd.conf <<\EOT
options nbd max_part=16
EOT

# Creating a bridge for the ONE network
$ cat > /etc/network/interfaces <<\EOT
auto lo
iface lo inet loopback

auto br0
iface br0 inet dhcp
    bridge_ports    eth0
    bridge_stp      off
    bridge_maxwait  0
    bridge_fd       0
EOT
```
## Preparing ONE for ONEDock
You need to update the file ```/etc/sudoers.d/opennebula``` to add the file that will configure the network. You need to add the line

```bash
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network, /usr/bin/qemu-nbd
```

And to activate this alias appending the alias in the following line

```bash
oneadmin ALL=(ALL) NOPASSWD: ONE_MISC, ONE_NET, ONE_LVM, ONE_ISCSI, ONE_OVS, ONE_XEN, ONEDOCK
```

Also you need to add the ```oneadmin``` user to the ```docker``` group, in order to be able to run docker containers.

```bash
$ usermod -aG docker oneadmin
```
