# Kit for Unix-like

## Setup Bash Environement 
Setup bash, aliases, paths and vars etc., just one line code to get things done:
```sh
bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)
```
For Windiows you can use [Git Bash](https://git-scm.com/downloads) indeed, it's same with Linux or Darwin.

You can boot it from local storage two.
```sh
# git clone it from github to <kit-local-dir>
git clone https://github.com/junjiemars/kit.git <kit-local-dir>

# boot up from <kit-local-dir>
GITHUB_H=<file://kit-local-dir> <kit-local-dir>/ul/setup-bash.sh  
```

## Setup Java Programming Environement
A tone of building and programming tools for Java, but you just need one line code to boot up.
```sh
HAS_ANT=1 \
HAS_MAVEN=1 \
HAS_GRADLE=1 \
HAS_BOOT=1 \
HAS_GROOVY=1 \
HAS_SCALA=1 \
bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
