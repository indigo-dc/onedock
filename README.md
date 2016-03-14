[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

# ONEDock
This project intends to provide support for OpenNebula to create Docker containers and deliver them to the end user as if they were Virtual Machines.

## Full Documentation

See the [Wiki](https://github.com/indigo-dc/onedock/wiki) for full documentation, examples, operational details and other information.

## FAQ (what to expect from ONEDock)

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
Well, ONEDock is under active development. 

Moreover Docker is also under very active development and, so, the integration with new versions may not work (e.g. in two weeks docker went from 1.8 to 1.9). Please tell us if you notice that problems arise with new versions.