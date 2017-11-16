# Kit for Docker

* [Docker on Linux](#docker-on-linux)
  * [Run docker client via non root](#run-docker-client-via-non-root)
* [Basic CentOS Development Environment](#basic-centos-development-environment)
  * [Build from Dockerfile](#build-from-dockerfile)
  * [Play with centos-dev Docker Container](#play-with-centos-dev-docker-container)
* [Basic Ubuntu Development Environment](#basic-ubuntu-development-environment)
  * [Build from Dockerfile](#build-from-dockerfile)
  * [Play with ubuntu-dev Docker Container](#play-with-ubuntu-dev-docker-container)
  * [Avoid slow apt-get update and install](#avoid-slow-apt-get-update-and-install)
* [Docker on Windows 10](#docker-on-windows-10)
  * [Hyper-V Default Locations](#hyper-v-default-locations)
  * [tty Issue](#tty-issue)
  * [Internal Virtual Switch](#internal-virtual-switch)
* [Basic Java Development Environment](#basic-java-development-environement)
  * [Build from Dockerfile](#build-from-dockerfile)
  * [Play with java-dev Docker Container](#play-with-java-dev-docker-container)
  * [Install Java Programming Environment](#install-java-programming-environment)
* [Docker for Database](#docker-for-database)
* [Docker Machine on Windows 10](#docker-machine-on-windows-10)
  * [Install Docker Toolbox](#install-docker-toolbox)
  * [Configure Docker Quickstart Terminal](#configure-docker-quickstart-terminal)
  * [Access Windows dir in Docker Host](#access-windows-dir-in-docker-host)
  * [tty mode](#tty-mode)
  * [Sharing Files](#sharing-files)
* [Networking](#networking)
  * [Bridge](#bridge)
  * [Overlay](#overlay)
  * [SSH between Containers](#ssh-between-containers)
  * [Tips](#tips)
* [Storage](#storage)

## Docker on Linux

### Run docker client via non root
Docker daemon run as root user in a group called __docker__ by default. 
```sh
sudo usermod -a -Gdocker <user>
sudo service docker[.io] restart
```
The final thing: reboot computer.


* Port connection
* Container linking

## Basic CentOS Development Environment
Include basic building/networking tools, emacs/vim editors for c/c++/clang/python/lua development.

You can use root or default sudoer: u/Hell0 to login and play.

### Build from Dockerfile
```sh
docker build -t centos-dev https://raw.githubusercontent.com/junjiemars/kit/master/docker/dev/centos.dockerfile
```

or you can download [centos.dockefile](https://raw.githubusercontent.com/junjiemars/kit/master/docker/dev/centos.dockerfile) then build from it.


### Play with centos-dev Docker Container
* once a time
```sh
docker run -w /home/u -h centos --privileged -u u -it --rm junjiemars/centos-dev /bin/bash
```
* as daemon
```sh
# gdb or lldb needs privileged permission
docker run --name centos-dev -w /home/u -h centos --privileged -d junjiemars/centos-dev
docker exec -it -u u centos-dev /bin/bash
```
* cannot change locale
```sh
localedef -i en_US -f UTF-8 en_US.UTF-8
```

## Basic Ubuntu Development Environment
Include basic building/networking tools, emacs/vim editors for c/c++/llvm/python/lua development.

You can use root or default sudoer: u/Hell0 to login and play.

It's like [Basic CentOS Development Environment](#basic-centos-development-environment)

### Build from Dockerfile
```sh
docker build -t ubuntu-dev https://raw.githubusercontent.com/junjiemars/kit/master/docker/dev/ubuntu.dockerfile
```

or you can download [ubuntu.dockefile](https://raw.githubusercontent.com/junjiemars/kit/master/docker/dev/ubuntu.dockerfile) then build from it.


### Play with ubuntu-dev Docker Container
* once a time
```sh
docker run -w /home/u -h ubuntu --privileged -u u -it --rm junjiemars/ubuntu-dev /bin/bash
```
* as daemon
```sh
docker run --name ubuntu-dev -w /home/u -h ubuntu --privileged -d junjiemars/ubuntu-dev
docker exec -it -u u ubuntu-dev /bin/bash
```

### Avoid slow apt-get update and install
* Avoid IPv6 if you use a slow tunnel
```sh
apt-get -o Acquire::ForceIPv4=true
```
* Use mirrors which is based on your geo location
```sh
# use mirror automatically
sudo cp /etc/apt/sources.list /etc/apt/sources.list.ori
sudo sed -i 's#http:\/\/archive.ubuntu.com\/ubuntu\/#mirror:\/\/mirrors.ubuntu.com\/mirrors.txt#' /etc/apt/sources.list

# check mirrors list that based on your geo
curl -sL mirrors.ubuntu.com/mirrors.txt
```
* Aovid posioning mirrors: select another country
```sh
```

## Docker on Windows 10
Now, the good news is Docker has native stable version for Windows 10 since 7/29/2016.

If you need __Docker Machine__ you can check [Docker Machine on Windows 10](#docker-machine-on-windows-10)

### Hyper-V Default Locations
* Control Panel > Administrative Tools > Hyper-V Manager
* Change __Virtual Machines__ location
* Change __Virtual Hard Disks__ location

### tty Issue
* Mintty does not provide full TTY support;
* Use __cmd__ or __PowerShell__;

### Internal Virtual Switch
* 

### Failed to Start
* Hyper-V Manager: keep only one MobiLinuxVM and delete all the others

## Basic Java Development Environment
* Building tools: [ant](http://ant.apache.org), [maven](https://maven.apache.org), [boot](http://boot-clj.com), [gradle](https://gradle.org);
* Java programming lanuage: [clojure](https://clojure.org), [groovy](http://www.groovy-lang.org), [scala](http://www.scala-lang.org);

### Build from Dockerfile
```sh
docker build -t java-dev https://raw.githubusercontent.com/junjiemars/kit/master/docker/dev/java.dockerfile
```

### Play with java-dev Docker Container
* one time
```sh
docker run -w /home/u -h centos -u u -it --rm java-dev /bin/bash
```
* as daemon
```sh
docker run --name java-dev -w /home/u -h centos --privileged -d java-dev 
docker exec -it -u u java-dev /bin/bash
```

### Install Java Programming Environment
Run into java-dev container and then run [install-java-kits.sh](https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```sh
HAS_ALL=YES install-java-kits.sh
```

## Docker for Database

### PostgreSQL

### Oracle
You can pull it from [Docker Hub](https://hub.docker.com/), 

or build it from [oracle_xe.dockerfile](https://raw.githubusercontent.com/junjiemars/kit/master/docker/db/oracle_xe.dockerfile)

Beside, Oracle XE 11g2 could not be downloaded via curl, there needs some hack way to do it.

```sh
docker pull junjiemars/xe11g2:latest
docker run --name xe11g2 -p 1521:1521 -p 8080:9000 -d junjiemars/xe11g2:latest
```


## Docker Machine on Windows 10
* Install Docker Toolbox
* Run Docker Quickstart Terminal
* Play docker, it's same on Linux box

### Install Docker Toolbox
* Kitematic is useless, don't install it
* Need VirtualBox and NIS6+

### Configure Docker Quickstart Terminal
* __Font__: On Windows, the Console's font is ugly if the code page is 936 for Chinese locale. Change the Windows locale to English and change the font to Consolas or others thats good for English lauguage. Restart Windows then switch the locale back to your locale, then restart it again.
* __Mintty__: Mintty is not based on Windows' Console, it's better than git-bash. To use Mintty via change Docker Quickstart Terminal's the target in *shortcut* to 
```
"C:\Program Files\Git\usr\bin\mintty.exe" -i "c:\Program Files\Docker Toolbox\docker-quickstart-terminal.ico" /usr/bin/bash --login -i  "c:\Program Files\Docker Toolbox\start.sh"
```
* __MACHINE_STORAGE_PATH__: Environment variable points to docker's image location.

### Access Windows dir in Docker Host
* Configure __Shared folders__ on VirtualBox: 
```
<vbox-folder-label-name> -> <windows-local-dir>
```
* Mount the dir on Docker VM:
```sh
docker-machine ssh [machine-name]
mkdir -p /home/docker/<dir-name>
sudo mount -t vboxsf -o uid=1000,gid=50 <vbox-folder-label-name> /home/docker/<dir-name>
```
* Run Docker Host with __Volume__:
```sh
docker run -d -v <vbox-folder-label-name>:<docker-host-mount-dir> <image>
```

### tty mode
If you got __cannot enable tty mode on non tty input__, so
```sh
docker-machine ssh <default>
```

### Sharing Files
* machine -> host:
```sh
docker-machine scp <machine>:<machine-path> <host-path>
```
* host -> machine:
```sh
docker-machine scp <host-path> <machine>:<machine-path>
```
* container -> host
```sh
# copy from container to machine 
docker cp <container-path> <machine-path>
# copy from machine to host
docker-machine scp <machine>:<machine-path> <host-path>
```
host -> container vice versa.

## Networking

### Bridge
The default **docker0** virtual bridge interface let communications:
* container -> container
* container -> host
* host -> container 
very easy.

### Overlay

### SSH between Containers
* _Read from socket failed: Connection reset by peer_ :
```sh
$ sudo ssh-keygen -t rsa -f /etc/ssh/ssh_hosts_rsa_key
$ sudo ssh-keygen -t dsa -f /etc/ssh/ssh_hosts_dsa_key
```

### Tips
* Container's IP address
```sh
# on default bridge network
$ docker inspect --format "{{.NetworkSettings.IPAddress}}" <container-id|container-name>

# on specified network
docker inspect --format "{{.NetworkSettings.Networks.<your-network>.IPAddress}}" <container-id|container-name>
```
* Link to Another Containers (/etc/hosts)
```sh
$ docker run --name n2 --link=n0 --link=n1 -d <docker-image>
```

## Storage

```sh
# create mount the volume on /opt/vol
$ docker run --name n0 -w /home/u -h n0 -v /opt/vol -d <docker-iamge>

# mount a host volume on /opt/vol
$ docker run --name n0 -w /home/u -h n0 -v <host-path>:/opt/vol -d <docker-image>

# mount a host file
$ docker run --name n0 -w /home/u -h n0 -v ~/.bash_history:/home/u/.bash_history -d <docker-image>
```
