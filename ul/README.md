# Kit for Unix-like

## Bash Environement 
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

## Java Programming Environement
A tone of building and programming tools for Java, but you just need one line code to boot up.

* Install JDK, ant, maven, gradle, boot, groovy and scala via one line code
```sh
HAS_ALL=YES bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
```sh
HAS_JDK=1 JDK_U="8u91" JDK_B="b14" bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Ant](http://ant.apache.org)
```sh
HAS_ANT=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Maven](https://maven.apache.org)
```sh
HAS_MAVEN=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Boot](http://boot-clj.com)
```sh
HAS_BOOT=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Gradle](https://gradle.org)
```sh
HAS_GRADLE=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Groovy](http://www.groovy-lang.org)
```sh
HAS_GROOVY=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```
* Just install [Scala](http://www.scala-lang.org)
```sh
HAS_SCALA=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)
```

# Tomcat Web Server

