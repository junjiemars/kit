# Docker Tutorial

## Run docker client via non root
Docker daemon run as the root user in the group called docker by default. 
sudo usermod -a -Gdocker <user>
sudo service docker[.io] restart
The final thing: reboot computer.


* Port connection
* Container linking