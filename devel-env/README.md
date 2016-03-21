# HOW to use
1. Create a "oneadmin" user in your deployment (this is to synchronize permissions)

```bash
$ sudo groupadd --gid 9869 oneadmin
$ sudo adduser --uid 9869 -g oneadmin oneadmin
```

2. Add your user to the oneadmin group
```bash
$ sudo usermod -aG oneadmin <my user>
```

At this point you should probably log out or use the new group:

```bash
$ newgrp oneadmin
```

3. Create the environment:

```bash
$ sudo ./setupenv
```

4. Create a front-end

```bash
$ ./startfrontend
```

5. Create a working node

```bash
$ ./startwn wn1
```

At this point you could also create more working nodes, but it is not recommended, because they will all find all the VMs (i.e. containers) when they are polled and that would probably have problems in ONE.