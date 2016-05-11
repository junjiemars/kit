# Docker Tutorial

## Run docker client via non root
Docker daemon run as the root user in the group called docker by default. 
sudo usermod -a -Gdocker <user>
sudo service docker[.io] restart
The final thing: reboot computer.


* Port connection
* Container linking

## Docker Machine on Windows 10
* Install Docker Toolbox
* Run Docker Quickstart Terminal
* Play docker, it's same on Linux box

### Install Docker Toolbox
* Kitematic is useless, don't install it
* Need VirtualBox and NIS6+

### Configure Docker Quickstart Terminal
* ***Font***: On Windows, the Console's font is ugly if the code page is 936 for Chinese locale. Change the Windows locale to English and change the font to Consolas or others thats good for English lauguage. Restart Windows then switch the locale back to your locale, then restart it again.
* ***Mintty***: Mintty is not based on Windows' Console, it's better than git-bash. To use Mintty via change Docker Quickstart Terminal's the target in *shortcut* to 
```
"C:\Program Files\Git\usr\bin\mintty.exe" -i "c:\Program Files\Docker Toolbox\docker-quickstart-terminal.ico" /usr/bin/bash --login -i  "c:\Program Files\Docker Toolbox\start.sh"
```

### Access Windows' dir in Docker Host
* Configure ***Shared folders*** on VirtualBox: 
```
<vbox-folder-label-name> -> <windows-local-dir>
```
* Mount the dir on Docker VM:
```
docker-machine ssh [machine-name]
mkdir -p /home/docker/<dir-name>
sudo mount -t vboxsf -o uid=1000,gid=50 <vbox-folder-label-name> /home/docker/<dir-name>
```
* Run Docker Host with ***Volume***:
```
docker run -d -v <vbox-folder-label-name>:<docker-host-mount-dir> <image>
```

### tty mode
If you got *** cannot enable tty mode on non tty input***, so
```sh
docker-machine ssh <default>
```
