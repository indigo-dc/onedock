# FAQ

1. <a href="#how">But, how does it work?</a>
1. <a href="#docker">This looks similar to ONE-enabled Docker-Machine. Is it?</a>
1. <a href="#interaction">Containers are different to VMs. Will the user interaction be different when using ONEDock?</a>
1. <a href="#use">Cool! How can I use it?</a>
1. <a href="#network">Wait a minute. You need to configure the network, right?</a>
1. <a href="#caveat">Sounds like magic! What is the caveat?</a>

<a name="how" />
## But, how does it work?
When you ask OpenNebula for a VM, a Docker container will be deployed. You will get an IP and you will be able to interact with it from OpenNebula as if it was a VM.

<a name="docker" />
## This looks similar to ONE-enabled Docker-Machine. Is it?
No. Docker Machine and other projects deploy VMs in different cloud providers (e.g. OpenNebula, OpenStack, Amazon EC2, etc.). Then, they install Docker on them and, afterwards, you can deploy Docker containers on top them.

Instead, ONEDock deploys Docker containers on top of bare-metal nodes, thus considering the containers as first-class citizens in OpenNebula.

<a name="interaction" />
## Containers are different to VMs. Will the user interaction be different when using ONEDock?
No. ONEDock almost fully integrates with OpenNebula, so the user can use the common ONE commands (i.e. onevm, oneimage, etc.) to interact with ONEDock. The very same interaction is maintained but, instead of deploying VMs, Docker containers are deployed.

<a name="use" />
## Cool! How can I use it?
1. You register an image using the ``oneimage`` command
2. ONEDock will download the image from Docker Hub
3. You request a VM that uses that image
4. ONEDock will create the container, and the container will be  daemonized (e.g. kept alive).
5. You can access the container (e.g. using ssh).

<a name="network" />
## Wait a minute. You need to configure the network, right?
Not actually. Different containers will have different IP addresses. All the ports are available in the IP address that ONE will assign to the container. Therefore, you do not need to deal with opening ports and all that stuff.

<a name="caveat" />
## Sounds like magic! What is the caveat?
Well, ONEDock is under active development. Some open issues are the VNC console in Sunstone and others.

Moreover Docker is also under very active development and, so, the integration with new versions may not work (e.g. in two weeks docker went from 1.8 to 1.9). Please tell us if you notice that problems arise with new versions.
