# Kit Oracle

## Export ORACLE_HOME or not?

## Where are imp/exp or sqlplus?
If you just want to use sqlplus, just download instantclient then use sqlplu.sh is ok. 
But if you will do imp/exp tasks and don't want to install Oracle, the follwing is for you.

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

