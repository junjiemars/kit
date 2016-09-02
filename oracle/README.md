# Kit for Oracle

* [SQL*Plus Kits](#sql*plus-kits)
  * [On Windows](#on-windows)
  * [On Unix-like](#on-unix-like) 
  * [How to Use](#how-to-use)
* [Import and Export](#import-and-export)
  * [Export Objects](#export-objects)
  * [Transform SQL File](#transform-sql-file)
* [Schema](#schema)
* [Tablespaces](#tablespaces)
* [Tables](#tables)
  * [Drop](#drop)

## SQL*Plus Kits 
If you just want to use [sqlplus](https://docs.oracle.com/cd/B19306_01/server.102/b14357/toc.htm), 
just download instantclient then use [sqlplu.sh](https://raw.githubusercontent.com/junjiemars/kit/master/oracle/sqlplus.sh) indeed. 
But what? if you will do imp/exp tasks and don't want to install Oracle, 
the follwing is for you.

### On Windows
* Download the Oracle installer.
* Extract the msi from setup.exe
```bat
REM /s silient
REM /x uninstall
REM /b extract the msi to location
REM /v pass the "/qn" arguments to Windows install to disable GUI output

setup.exe /s /x /b"<store-extracted-msi-dir>" /v"/qn"
```

* Extract the files from the msi
```bat
msiexec /a <x-msi> targetdir=<where-dir> /qn
```

### On Unix-like
* On RedHat
```sh
rpm2cpio <x.rpm>
```
* On Ubuntu
```sh
sudo apt-get install rpm2cpio
rpm2cpio <x.rpm> | cpio -i --make-directories
```

### How to Use
The critical script is [sqlplus.sh](https://raw.githubusercontent.com/junjiemars/kit/master/oracle/sqlplus.sh).
[oracle.sh](https://raw.githubusercontent.com/junjiemars/kit/master/oracle/oracle.sh) is a general wrapper 
for all of Oracle's commands.

* Interactive Mode
```sh
# login
$ sqlplus.sh
$ sqlplus.sh username/passwword
$ sqlplus.sh username/password@host:port/sid

# parameterized 
$ ORACLE_HOME=<ur-oracle-home> sqlplus.sh username/password@host:port/sid

# general style via oracle.sh
$ CMD=sqlplus.sh oracle.sh username/password@host:port/sid
```

* Command Line Mode
```sh
# run sql script
$ cat users.sql | sqlplus.sh username/password@host:port/sid
$ sqlplus.sh username/password@host:port/sid @users

# parameterized 
cat users.sql | sqlplus.sh username/password@host:port/sid
```

## Import and Export

### Export Objects

### Transform SQL File
Transform the tablespace and schema from file.

* Transform Tablespace
```sh
$ eoo.sh -dsqlfile -f<sql-file> -t<from-tablespace:to-tablespace>
```
* Transform Schema
```sh
$ eoo.sh -dsqlfile -f<sql-file> -u<from-user:to-user>
```
* Or Both
```sh
$ eoo.sh -dsqlfile -f<sql-file> -t<from-tablespace:to-tablespace> -u<from-user:to-user>
```

## Schema

### Login
* As SYSDBA Role

Must on the machine which Oracle instance running on.
```sh
$ sqlplus system/passwd
SQL> alter user sys identified by passwd;
SQL> connect sys/passwd as sysdba;
```
* As SYSTEM User

## Tablespaces

## Tables

### Drop