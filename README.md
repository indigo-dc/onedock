# ONEDock
This project intends to provide support for OpenNebula to create Docker containers and deliver them to the end user as if they were Virtual Machines.

## Index
* [0. FAQ (what to expect from ONEDock)](#0-faq-what-to-expect-from-onedock)
* [1. Assumptions](#1-assumptions)
* [2. Environment](#2-environment)
* [3. Installation](#3-installation)
* [4. Using ONEDock](#4-using-onedock)
* [5. Quick deployment of a testing environment](#5-quick-deployment-of-a-testing-environment)
* [6. Advanced usage](#6-advanced-usage)

## 0. FAQ (what to expect from ONEDock)

### What is ONEDock?
ONEDock is a set of extensions for [OpenNebula](http://www.opennebula.org) to use containers as if they were virtual machines (VM).

The concept of ONEDock is to configure Docker to act as an hypervisor. It behaves just as KVM does in the context of OpenNebula.
### But, how does it work?
When you ask OpenNebula for a VM, a Docker container will be deployed. You will get an IP and you will be able to interact with it from OpenNebula as if it was a VM.

### This looks similar to ONE-enabled Docker-Machine. Is it?
No. Docker Machine and other projects deploy VMs in different cloud providers (e.g. OpenNebula, OpenStack, Amazon EC2, etc.). Then, they install Docker on them and, afterwards, you can deploy Docker containers on top them.

Instead, ONEDock deploys Docker containers on top of bare-metal nodes, thus considering the containers as first-class citizens in OpenNebula.

### Containers are different to VMs. Will the user interaction be different when using ONEDock?
No. ONEDock almost fully integrates with OpenNebula, so the user can use the common ONE commands (i.e. onevm, oneimage, etc.) to interact with ONEDock. The very same interaction is maintained but, instead of deploying VMs, Docker containers are deployed.

### Cool! How does it work?
1. You register an image using the ``oneimage`` command
2. ONEDock will download the image from Docker Hub
3. You request a VM that uses that image
4. ONEDock will create the container, and the container will be  daemonized (e.g. kept alive).
5. You can access the container (e.g. using ssh).

### Wait a minute. You need to configure the network, right?
Not actually. Different containers will have different IP addresses. All the ports are available in the IP address that ONE will assign to the container. Therefore, you do not need to deal with opening ports and all that stuff.

### Sounds like magic! What is the caveat?
Well, ONEDock is under active development. Some open issues are the VNC console in Sunstone and others.

Moreover Docker is also under very active development and, so, the integration with new versions may not work (e.g. in two weeks docker went from 1.8 to 1.9). Please tell us if you notice that problems arise with new versions.

## 1. Assumptions

You have a linux installation with [OpenNebula](http://www.opennebula.org) on it. It is assumed that you have a local Docker registry v2.0 installed in a host (named dockerregistry), which is the same ONE frontend. Moreover the folder in which the docker images are stored is known and it is accessible from the command line. If you do not have such deployment please follow the instruction of section [_Quick deployment of a test environment_](#5-quick-deployment-of-a-testing-environment).

## 2. Environment

This project has been tested under the following environment (for both the front-end and the working nodes)
* Ubuntu 14.04
* jq, xmlstarlet, bridge-utils and qemu-utils packages installed
* ONE 4.12
* Docker 1.9
* user oneadmin is able to execute docker (i.e. is in group "docker"; usermod -aG docker oneadmin)

## 3. Installation

### 3.1 Front-end node

#### 3.1.1 Prerrequisites

##### 3.1.1.1. OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official OpenNebula documentation (e.g. [for Ubuntu](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_ubuntu_kvm.html)).

##### 3.1.1.2 Docker
Then you have to install Docker, according to the official documentation (e.g. for [Ubuntu](https://docs.docker.com/engine/installation/ubuntulinux/)).

You need to install a Docker Registry v2.0 that is usable from all the nodes. Its name must be included in the variable ```LOCAL_SERVER``` in the file ```/var/lib/one/remotes/onedock.conf```.

_REMEMBER_ to install the certificates of your Docker registry in the proper directories. The most easy way to install the certificate is to copy it into the folder ```/etc/docker/certs.d/$HOSTNAME:5000/```. But you should copy it for the whole system in case that you want to use other commands (e.g. curl).

For the case of ubuntu, you can use a code like this:

```bash
mkdir -p /etc/docker/certs.d/onedockdemo:5000/
cp domain.crt /usr/local/share/ca-certificates/
cp domain.crt /etc/docker/certs.d/onedockdemo:5000/
update-ca-certificates
```

##### 3.1.1.3 Required packages
Now install the required packages: jq, xmlstarlet, qemu-utils and bridge-utils.

```bash
apt-get -y install jq xmlstarlet qemu-utils bridge-utils.
```

#### 3.1.2 Installation of ONEDock and activating it in ONE

Once OpenNebula, Docker, a Docker Registry and the required packages have been installed, you can install ONEDock as follows (as root user):

```bash
cd /tmp/
git clone https://github.com/indigo-dc/onedock
cd onedock
./setup_files.sh
```

ONEDock will be installed. Then you should adjust the variables in ```/var/lib/one/remotes/onedock.conf``` according to your deployment. In particular:

* LOCAL_SERVER points to the local docker registry
* DATASTORE_DATA_PATH points to the folder in which the images in the docker registry are stored

In order to activate ONEDock in ONE, you just need to update the /etc/one/oned.conf file.

```bash
cat >> /etc/one/oned.conf << EOF
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
### 3.2 Computing nodes

#### 3.2.1 Installation of OpenNebula, Docker and the required packages

##### 3.2.1.1. OpenNebula
You have to install OpenNebula (i.e. installing the opennebula-node package, the shared directories, the network bridge, etc.). That means that the OpenNebula node should be installed as if it was going to run KVM Virtual Machines. You can follow the instructions in the official OpenNebula documentation (e.g. [for Ubuntu](http://docs.opennebula.org/4.14/design_and_installation/quick_starts/qs_ubuntu_kvm.html)).

##### 3.2.1.2 Docker
Then you have to install Docker, according to the official documentation (e.g. for [Ubuntu](https://docs.docker.com/engine/installation/ubuntulinux/)).

_REMEMBER_ to install the certificates of your Docker registry in the proper directories. The most easy way to install the certificate is to copy it into the folder ```/etc/docker/certs.d/$HOSTNAME:5000/```. But you should copy it for the whole system in case that you want to use other commands (e.g. curl).

For the case of ubuntu, you can use a code like this:

```bash
mkdir -p /etc/docker/certs.d/onedockdemo:5000/
cp domain.crt /usr/local/share/ca-certificates/
cp domain.crt /etc/docker/certs.d/onedockdemo:5000/
update-ca-certificates
```

##### 3.2.1.3 Required packages
Now install the required packages: jq, xmlstarlet, qemu-utils and bridge-utils.

```bash
apt-get -y install jq xmlstarlet qemu-utils bridge-utils.
```

##### 3.2.1.4 Full code for impatients

If you are impatient, you can try the following code, which works for Ubuntu 14.04, but this step is very dependent from your installation and you should check out what are you doing:

```bash
# Keys de ONE
wget -q -O- http://downloads.opennebula.org/repo/Ubuntu/repo.key | apt-key add
echo "deb http://downloads.opennebula.org/repo/4.14/Ubuntu/14.04/ stable opennebula" > /etc/apt/sources.list.d/opennebula.list

# Keys de Docker
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
cat << EOT > /etc/apt/sources.list.d/docker.list
# Ubuntu Trusty 14.04 (LTS)
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOT

# Instalacion de docker y one
apt-get -y update
apt-get -y install opennebula-node nfs-common bridge-utils docker-engine jq xmlstarlet

# The oneadmin user should be able to run docker
usermod -aG docker oneadmin

# Starting the nbd module and setting it persistent
modprobe nbd max_part=16
echo "nbd" >> /etc/modules

cat > /etc/modprobe.d/nbd.conf <<\EOT
options nbd max_part=16
EOT

# Creating a bridge for the ONE network
cat > /etc/network/interfaces <<\EOT
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

#### 3.2.2 Preparing ONE for ONEDock

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
usermod -aG docker oneadmin
```

## 4. Using ONEDock

### 4.1 Creating the datastore

To create the datastore you just have to create a new datastore using the onedock type for both datastores and transfer manager. An example (as oneadmin):

```bash
$ cat > onedock.ds << EOF
NAME=onedock
DS_MAD=onedock
TM_MAD=onedock
EOF
$ onedatastore create onedock.ds
```

### 4.2 Creating images
First, switch to the oneadmin account:
```
sudo su - oneadmin
```

Then you have to create a image in the new datastore. An example (as oneadmin):

```bash
$ cat > ubuntu-docker.tmpl << EOF
NAME="ubuntu"
PATH=docker://rastasheep/ubuntu-sshd
TYPE=OS
DESCRIPTION="Ubuntu Trusty with SSHd"
EOF
$ oneimage create -d onedock ubuntu-docker.tmpl
```

The PATH can be set to a real image in docker hub (prepending _docker://_ and using the docker hub notation) or to a docker image file exported by using the command ```docker save```. In case that the path points to a docker resource, ONEDock will download it to the local registry to avoid that the internal nodes have to get it from the Internet.

### 4.3 Creating a virtual network

You have to create a virtual network to be used for the containers. An example (as oneadmin), that has to be customized for your network and your bridge:
```bash
$ cat > docker-private.net << EOF
NAME=private
BRIDGE=docker0
NETWORK_ADDRESS = "172.17.42.1"
NETWORK_MASK    = "255.255.0.0"
DNS             = "172.17.42.1"
GATEWAY         = "172.17.42.1"
AR=[TYPE = "IP4", IP = "172.17.10.1", SIZE = "100" ]
EOF
$ onevnet create docker-private.net
```

In this example we assume that the we are using the ```docker0``` bridge, and it allows packet forwarding and network access to the containers, but you can create your own bridges (e.g. br0, br1, etc.) to configure your network as usual.

This example also assumes some specific network parameters, but you should set the parameters of your network (i.e. IP address, DNS, gateway etc.).

You can list the details of the ``docker0` interface to find out the correct values for DNS and GATEWAY:
```
$ ifconfig docker0
docker0   Link encap:Ethernet  HWaddr 02:42:cd:ae:8a:e2  
          inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:cdff:feae:8ae2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:17476 errors:0 dropped:0 overruns:0 frame:0
          TX packets:19686 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:965292 (965.2 KB)  TX bytes:67255682 (67.2 MB)
```
In the previous example, these should be set to 172.17.0.1.

### 4.4 Adding a virtualization host

Now you should add some virtualization hosts, as usual. You can use the onedock VMM:

```bash
$ onehost create $HOSTNAME -i onedock -v onedock -n dummy
```
The use of $HOSTNAME in this particular case is for using the OpenNebula front-end as one of the hosts on which to deploy containers.

### 4.5 Docker container deployment

Finally you can deploy one Docker container out of that image:

```bash
onevm create --memory 512 --cpu 1 --disk ubuntu --nic private --net_context
```

(where the parameter --disk ubuntu points to the just created image id).

Notice that the very same OpenNebula interfaces are used but instead of deploying a VM, a Docker container.

## 5. Quick deployment of a testing environment

In the folder ```install``` you have a set of scripts that will help you deploy a testing environment.

### 5.1 Scenario #1: Using Vagrant

1. Install [Vagrant](http://vagrantup.com/)
2. cd vagrant
3. vagrant up

This installs OpenNebula with OneDock support.

4. vagrant ssh
5. sudo su - oneadmin
6. onevm create --memory 512 --cpu 1 --disk ubuntu --nic private --net_context

You can use ``onevm show`` to find out the IP and connect to the container using SSH.

### 5.2 Scenario #2: Using it in a VM (or bare metal)

Clone the repository and get into the folder
```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock
```

Then install as needed

1. Install ONE
      ``` $ sudo ./install/install-one ```
2. Install Docker
      ``` $ sudo ./install/install-docker ```
3. Install the docker-registry
      ``` $ sudo ./install/install-registry ```
4. Launch the docker-registry
      ``` $ sudo ./install/launch-registry ```
5. Follow the instructions in _Installation_ section or execute
      ``` $ sudo ./install/install-onedock ```

### 5.3 Scenario #3: Using it into a lxc container

If you want a single-node stand-alone installation of ONEDock, you can get a running _lxc_ container in an ubuntu 14.04 distro by simply executing the next commands (this installation assumes that you have installed lxc):

```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock/install
$ ./create-lxc ashlan --create
$ lxc-attach -n ashlan
```

Now you can go to section [using ONEDock](#4-using-onedock), and start using ONE.

## 6. Advanced usage

Onedock tries to be more than an proof of concept and that is why it tries to provide some advanced features to better using the containers as VMs.

### Overriding the command in the docker image

The default behaviour of onedock is to execute the container as-is, including the "daemonizing" flag (-d). That means that the command that is executed inside the container is the one included in the Dockerfile used for its creation. You can check it by issuing the next command:

```docker inspect -f '{{.Config.Cmd}}' <image>```.

In onedock it is possible to override that command. There are two methods:

1. In the onedock.conf file you can use the configuration variable ONEDOCK_DEFAULT_DOCKERRUN and set it to the command that will be used by default for any command. That means that the command execute to launch the container will be something like the next:

      ``` $ docker run -id ubuntu:latest $ONEDOCK_DEFAULT_DOCKERRUN ```

      It is advisable to use the setting ```ONEDOCK_DEFAULT_DOCKERRUN=/bin/bash``` to avoid extrange behaviours for the containers (e.g. a VM finalizes as it is created because the command is set to /bin/true, or the image contains some kind of malware).

2. At the moment of the creation of the image, you can use the tag DOCKERRUN to set the specific command that should be used for that specific image. In our example in previous sections, the tag can be included as in the next paragraph:

      ```
      NAME="ubuntu"
      PATH=docker://rastasheep/ubuntu-sshd
      TYPE=OS
      DESCRIPTION="Ubuntu Trusty with SSHd"
      DOCKERRUN=/bin/sshd -D
      ```

      That means that the command used to execute the container will be something like the next:

      ``` $ docker run -id rastasheep/ubuntu-sshd /bin/ssh -D```
