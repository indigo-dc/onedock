# ONEDock
This project intends to provide support for OpenNebula to create docker containers and deliver them to the end-user as it they were Virtual Machines.

## Assumptions

It is assumed that you have a local docker registry v2.0 installed in a host (named dockerregistry), which is the same ONE frontend. Moreover the folder in which the docker images are stored is known and it is accesible from the commandline. If you do not have such deployment please follow the instruction of section _Quick deployment of a local docker registry_.

## Environment

This project has been tested under the next environment (for both front-end and working nodes)
* Ubuntu 14.04
* jq package installed
* ONE 4.12
* user oneadmin is able to execute docker (i.e. is in group "docker"; usermod -aG docker oneadmin)

## Installation

Once ONE has been installed and the jq package has also been installed, you can install ONEDock as follows (as root user):

```
cd /tmp/
git clone https://github.com/indigo-dc/onedock
cd onedock
./setup_files.sh
```

ONEDock will be installed. The you should adjust the variables in ```/var/lib/one/remotes/onedock.conf``` according to your deployment. In particular

* LOCAL_SERVER point to the local docker registry
* DATASTORE_DATA_PATH points to the folder in which are stored the images in the docker registry

## Activate ONEDock in ONE

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

## Using

### Creating the datastore

To create the datastore you just have to create a new datastore using the onedock type for both datastores and transfer manager. An example (as oneadmin):

```
$ cat > onedock.ds << EOF
NAME=onedock
DS_MAD=onedock
TM_MAD=onedock
EOF
$ onedatastore create onedock.ds
```

Then you have to create a image in the new datastore. An example (as oneadmin):

```
$ cat > ubuntu-docker.tmpl << EOF
NAME="ubuntu"
PATH=ubuntu:latest
TYPE=OS
DESCRIPTION="Imagen de Ubuntu"
EOF
$ oneimage create -d onedock ubuntu-docker.tmpl
```

The PATH has to be set to a real image in docker hub, using the docker hub notation. ONEDock will download it to the local registry to avoid that the internal nodes have to get it from the Internet.

Finally you can create one VM that makes use of that image:

```
onevm create --memory 512 --cpu 1 --disk 1
```
(where the parameter --disk 1 points to the just created image id).

## Quick deployment of a local docker registry

This is a quick set of instruction with no explanation to install a local docker registry.

```bash
mkdir -p /var/lib/docker-registry/data
cd /var/lib/docker-registry/
mkdir -p certs && openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key -x509 -days 365 -out certs/domain.crt
mkdir -p /etc/docker/certs.d/onedock:5000/
cp /var/lib/docker-registry/certs/domain.crt /etc/docker/certs.d/onedock\:5000/
cp /var/lib/docker-registry/certs/domain.crt /usr/local/share/ca-certificates/
update-ca-certificates
docker run -d -p 5000:5000 --restart=always --name registry -v /var/lib/docker-registry/data:/var/lib/registry -v /var/lib/docker-registry/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key registry:2
```

### Checking the registry
```
$ curl -X GET https://onedock:5000/v2/
$ docker pull ubuntu:latest
$ docker tag ubuntu onedock:5000/ubuntu:latest
$ docker push onedock:5000/ubuntu
$ curl -X GET https://onedock:5000/v2/_catalog
{"repositories":["ubuntu"]}
$ curl -X GET https://onedock:5000/v2/ubuntu/tags/list
{"name":"ubuntu","tags":["latest"]}

```

