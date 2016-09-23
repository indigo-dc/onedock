# Advanced usage
Onedock tries to be more than an proof of concept and that is why it tries to provide some advanced features to better using the containers as VMs.

## Overriding the command in the docker image

The default behaviour of onedock is to execute the container as-is, including the "daemonizing" flag (-d). That means that the command that is executed inside the container is the one included in the Dockerfile used for its creation. You can check it by issuing the next command:

```
$ docker inspect -f '{{.Config.Cmd}}' <image>
```

In onedock it is possible to override that command. There are two methods:

1. In the onedock.conf file you can use the configuration variable ONEDOCK_DEFAULT_DOCKERRUN and set it to the command that will be used by default for any command. That means that the command execute to launch the container will be something like the next:

      ```
      $ docker run -id ubuntu:latest $ONEDOCK_DEFAULT_DOCKERRUN
      ```

      It is advisable to use the setting `ONEDOCK_DEFAULT_DOCKERRUN=/bin/bash` to avoid strange behaviours for the containers (e.g. a VM finalizes as it is created because the command is set to /bin/true, or the image contains some kind of malware).

2. At the moment of the creation of the image, you can use the tag DOCKERRUN to set the specific command that should be used for that specific image. In our example in previous sections, the tag can be included as in the next paragraph:

      ```
      NAME="ubuntu"
      PATH=docker://rastasheep/ubuntu-sshd
      TYPE=OS
      DESCRIPTION="Ubuntu Trusty with SSHd"
      DOCKERRUN=/bin/sshd -D
      ```

      That means that the command used to execute the container will be something like the next:

      ```
      $ docker run -id rastasheep/ubuntu-sshd /bin/ssh -D
      ```
