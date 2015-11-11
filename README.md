# ONEDock
This project intends to provide support for OpenNebula to create docker containers and deliver them to the end-user as it they were Virtual Machines.

## 0. FAQ (what to expect from ONEDock)

### What is ONEDock?
ONEDock is a set of extensions for [OpenNebula](http://www.opennebula.org) that enable to use containers as if they were virtual machines (VM).

The concept of ONEDock is to configure Docker to act as an hypervisor. It behaves just as kvm does in the context of OpenNebula.
### But, how does it work?
When you ask OpenNebula for a VM, a container will be deployed. Then you will get an IP and you will be able to interact with it as if it was a VM.

### I think that it is similar to ONE-enabled Docker-Machine. Is it?
No. Docker Machine and other projects deploy VMs in different cloud providers (e.g. OpenNebula, OpenStack, Amazon EC2, etc.). And they install docker on them. Then you can deploy docker containers on them. 

ONEDock deploys docker containers on top of bare-metal nodes, considering the containers as first-class virtualization resources.

### Containers are different to VM. Will the end-user need to learn new things?
No. ONEDock almost fully integrates with ONE, so the user can use the comon ONE commands (i.e. onevm, oneimage, etc.) to interact with ONEDock.

### It seems cool... How does it work?
1. You register a image using the oneimage command
2. ONEDock will download the image from docker hub
3. You request a VM that uses the image
4. ONEDock will create the container, and will daemonize.
5. You can access the container (e.g. using ssh).

### But wait a minute... you need to configure the network?
No. All the ports are available in the IP address that ONE will assign to the container. So you do not need to deal with opening ports and all that stuff.

### It sounds like magic! What is the caveat?
Well, ONEDock is under active development. Some open issues are the VNC console in sunstone and others.

Moreover Docker is also under a very active development and so the integration with new versions may not work (e.g. in 2 weeks docker went from 1.8 to 1.9). Please tell us if you notice that problems arise with new versions.

## 1. Assumptions

You have a linux installation with [OpenNebula](http://www.opennebula.org) on it. It is assumed that you have a local docker registry v2.0 installed in a host (named dockerregistry), which is the same ONE frontend. Moreover the folder in which the docker images are stored is known and it is accesible from the commandline. If you do not have such deployment please follow the instruction of section _Quick deployment of a test environment_.

## 2. Environment

This project has been tested under the next environment (for both front-end and working nodes)
* Ubuntu 14.04
* jq package installed
* ONE 4.12
* user oneadmin is able to execute docker (i.e. is in group "docker"; usermod -aG docker oneadmin)

## 3. Installation

### 3.1 Front-end node

Once ONE has been installed and the jq package has also been installed, you can install ONEDock as follows (as root user):

```bash
cd /tmp/
git clone https://github.com/indigo-dc/onedock
cd onedock
./setup_files.sh
```

ONEDock will be installed. The you should adjust the variables in ```/var/lib/one/remotes/onedock.conf``` according to your deployment. In particular

* LOCAL_SERVER point to the local docker registry
* DATASTORE_DATA_PATH points to the folder in which are stored the images in the docker registry

#### 3.1.1 Activate ONEDock in ONE

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

```
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

You need to update the file ```/etc/sudoers.d/opennebula``` to add the file that will configure the network. You need to add the line

```bash
Cmnd_Alias ONEDOCK = /var/tmp/one/docker-manage-network
```

And to activate this alias appending the alias in the following line

```bash
oneadmin ALL=(ALL) NOPASSWD: ONE_MISC, ONE_NET, ONE_LVM, ONE_ISCSI, ONE_OVS, ONE_XEN, ONEDOCK
```

## 4. Using ONEDock

### 4.1 Creating the datastore

To create the datastore you just have to create a new datastore using the onedock type for both datastores and transfer manager. An example (as oneadmin):

```
$ cat > onedock.ds << EOF
NAME=onedock
DS_MAD=onedock
TM_MAD=onedock
EOF
$ onedatastore create onedock.ds
```

### 4.2 Creating images

Then you have to create a image in the new datastore. An example (as oneadmin):

```
$ cat > ubuntu-docker.tmpl << EOF
NAME="ubuntu"
PATH=docker://ubuntu:latest
TYPE=OS
DESCRIPTION="Imagen de Ubuntu"
EOF
$ oneimage create -d onedock ubuntu-docker.tmpl
```

The PATH can be set to a real image in docker hub (prepending _docker://_ and using the docker hub notation) or to a docker image file exported by using the command ```docker save```. In case that the path points to a docker resource, ONEDock will download it to the local registry to avoid that the internal nodes have to get it from the Internet.

### 4.3 Creating a virtual network

You have to create a virtual network to be used for the containers. An example (as oneadmin):
```
cat > docker-private.net << EOF
NAME=private
BRIDGE=docker0
NETWORK_ADDRESS = "172.17.42.1"
NETWORK_MASK    = "255.255.0.0"
DNS             = "172.17.42.1"
GATEWAY         = "172.17.42.1"
AR=[TYPE = "IP4", IP = "172.17.10.1", SIZE = "100" ]
EOF
onevnet create private.net 
```

In this example we assume that the we are using the ```docker0``` bridge, and it allows packet forwarding and network access to the containers, but you can create your own bridges (e.g. br0, br1, etc.) to configure your network as usual.

This example also assumes some specific network parameters, but you should set the parameters of your network (i.e. IP adrress, DNS, gateway etc.).

### 4.4 Adding a virtualization host

Now you should add some virtualization hosts, as usual. You can use the onedock VMM:

```bash
$ onehost create onedock -i onedock -v onedock -n dummy
```

### 4.5 VM creation

Finally you can create one VM that makes use of that image:

```bash
onevm create --memory 512 --cpu 1 --disk ubuntu --nic private --net_context
```

(where the parameter --disk 1 points to the just created image id).

## 5. Quick deployment of a testing environment

In folder ```install``` you have a set of scripts that will help you to have a testing environment.

### 5.1 Scenario #1: Using it in a VM (or bare metal)

Clone the repository and get into the folder
```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock
```

Then install as needed

1. Install ONE
      ``` $ install/install-one ```
2. Install Docker
      ``` $ install/install-docker ```
3. Install the docker-registry
      ``` $ install/install-registry ```
4. Follow the instructions in _Installation_ section or execute
      ``` $ install/install-onedock ```

### 5.2 Scenario #2: Using it into a lxc container

If you want a single-node stand-alone installation of ONEDock, you can get a running _lxc_ container in an ubuntu 14.04 distro by simply executing the next commands:

```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock/install
$ ./create-lxc ashlan --create
```

Warning: This is not as easy as it seems... sometimes docker fails to start and you need to delete the /var/lib/docker folder, restart docker by hand and re-launch the registry.
