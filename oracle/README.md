# Oracle

## Export ORACLE_HOME or not?


## Where are imp, exp or sqlplus?
If u just want to use sqlplus, just download instantclient then use sqlplu.sh is ok. But if u will do imp/exp tasks and don't want to install Oracle, the follwing is for u.

### On Windows
* Download the Oracle installer.
* Extract the msi from setup.exe
```
setup.exe /s /x /b"<store-extracted-msi-dir>" /v"/qn"
```
/s silient
/x uninstall
/b extract the msi to location
/v pass the "/qn" arguments to Windows install to disable GUI output
* Extract the files from the msi
```
msiexec /a <x-msi> targetdir=<where-dir> /qn
```

### On Unix-like
* On RedHat
```shell
rpm2cpio <x.rpm>
```
* On Ubuntu
```shell
sudo apt-get install rpm2cpio
rpm2cpio <x.rpm> | cpio -i --make-directories
```

