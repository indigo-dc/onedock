# Quick deployment of a testing environment
1. <a href="#vagrant">Using Vagrant</a>
1. <a href="#metal">Using it in a VM (or bare metal)</a>
1. <a href="#lxc">Using it into a lxc container</a>

In the folder ```install``` you have a set of scripts that will help you deploy a testing environment.

<a name="vagrant" />
## Using Vagrant

1. Install [Vagrant](http://vagrantup.com/)
2. cd vagrant
3. vagrant up

This installs OpenNebula with OneDock support.

4. vagrant ssh
5. sudo su - oneadmin
6. onevm create --memory 512 --cpu 1 --disk ubuntu --nic private --net_context

You can use `onevm show` to find out the IP and connect to the container using SSH.

<a name="metal" />
## Using it in a VM (or bare metal)

Clone the repository and get into the folder
```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock
```

Then install as needed

1. Install ONE ` $ sudo ./install/ubuntu/install-one `
2. Install Docker ` $ sudo ./install/ubuntu/install-docker `
3. Install the docker-registry ` $ sudo ./install/ubuntu/install-registry `
4. Launch the docker-registry ` $ sudo ./install/ubuntu/launch-registry `
5. Follow the instructions in the <a href="#installation">_Installation_</a> section or execute ` $ sudo ./install/ubuntu/install-onedock `

In this example we use the ubuntu scripts, but be aware that there are also scripts to install ONEDock in CentOS7.

<a name="lxc" />
## Using it into a lxc container

If you want a single-node stand-alone installation of ONEDock, you can get a running _lxc_ container in an ubuntu 14.04 distro by simply executing the next commands (this installation assumes that you have installed lxc):

```bash
$ git clone https://github.com/indigo-dc/onedock
$ cd onedock/install/lxc
$ ./create-lxc ashlan --create
$ lxc-attach -n ashlan
```

Now you can go to the next section, <a href="#using">_Using ONEDock_</a>, and start using ONE.
