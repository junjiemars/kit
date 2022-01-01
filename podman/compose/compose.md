# Docker Compose


* [ZooKeeper](#zookeeper)
  * [Standalone](#standalone)
* [References](#references)


## ZooKeeper

### Install
```HAS_ZOOKEEPER=1 ZOOKEEPER_VER="3.4.10" bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)```

### Standalone
* download ZooKeeper's standalone compose file:
```curl -LO "https://raw.githubusercontent.com/junjiemars/kit/master/docker/compose/zookeeper-standalone.yml"```
* up:
```docker-compose -f <path-zookeeper-standalone.yml> up```
* logs:
```docker-compose -f <path-zookeeper-standalone.yml> logs```

__ISSUE__:
if ```bin/zkServer.sh start``` will cause docker exit with code ```0```


## References
* [ZooKeeper Getting Started Guide](https://zookeeper.apache.org/doc/r3.3.3/zookeeperStarted.html)
* [ZooKeeper Programmer's Guide](https://zookeeper.apache.org/doc/r3.3.3/zookeeperProgrammers.html#ch_programStructureWithExample)
* [Get started with Docker Compose](https://docs.docker.com/compose/gettingstarted/)
* [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/)
* [ZooKeeper Administrator's Guide](https://zookeeper.apache.org/doc/r3.3.1/zookeeperAdmin.html)
* [ZooKeeper JMX](https://zookeeper.apache.org/doc/r3.3.1/zookeeperJMX.html)
* [ZooKeeper Official Repository](https://hub.docker.com/_/zookeeper/)
