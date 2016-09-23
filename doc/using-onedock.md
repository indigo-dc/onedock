# Using OneDock
1. <a href="#datastore">Creating the datastore</a>
1. <a href="#images">Creating images</a>
1. <a href="#network">Creating a virtual network</a>
1. <a href="#host">Adding a virtualization host</a>
1. <a href="#deployment">Docker container deployment</a>

All this examples have been carried out using the _oneadmin_ user. If you installed opennebula successfully you should be able to switch to the oneadmin account:
```
sudo su - oneadmin
```

<a name="datastore" />
## Creating the datastore

To create the datastore you just have to create a new datastore using the onedock type for both datastores and transfer manager. An example (as oneadmin):

```bash
$ cat > onedock.ds << EOF
NAME=onedock
DS_MAD=onedock
TM_MAD=onedock
EOF
$ onedatastore create onedock.ds
```

<a name="images" />
## Creating images

Then you have to create a image in the new datastore. An example (as oneadmin):

```bash
$ cat > ubuntu-docker.tmpl << EOF
NAME="ubuntu"
PATH=docker://ubuntu:latest
TYPE=OS
DESCRIPTION="Ubuntu"
EOF
$ oneimage create -d onedock ubuntu-docker.tmpl
```

The PATH can be set to a real image in docker hub (prepending _docker://_ and using the docker hub notation) or to a docker image file exported by using the command ```docker save```. In case that the path points to a docker resource, ONEDock will download it to the local registry to avoid that the internal nodes have to get it from the Internet.
To be able to use the image you have to wait until it's in "rdy" state.


<a name="network" />
## Creating a virtual network

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

You can list the details of the `docker0` interface to find out the correct values for DNS and GATEWAY:
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

<a name="host" />
## Adding a virtualization host

Now you should add some virtualization hosts, as usual. You can use the onedock VMM:

```bash
$ onehost create $HOSTNAME -i onedock -v onedock -n dummy
```

The use of $HOSTNAME in this particular case is for using the OpenNebula front-end as one of the hosts on which to deploy containers.

<a name="deployment" />
## Docker container deployment

Finally you can deploy one Docker container out of that image:

```bash
$ onevm create --memory 512 --cpu 1 --disk ubuntu --nic private --net_context
```
(where the parameter --disk ubuntu points to the just created image id).

To be able to use the container you have to wait until it's in "runn" state.

Notice that the very same OpenNebula interfaces are used but instead of deploying a VM, a Docker container is deployed.
