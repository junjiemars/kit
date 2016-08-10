# Kit for Windows

* [Bash Environment](#bash-environment)
  * [Git-Bash](#git-bash)
  * [Bash in Docker](#bash-in-docker)
* [Encoding](#encoding)

## Bash Environment
Bash is awsome tool for Windows, but let it works perfectly and as 
your daily kit we needs some little tricks.

I flavor one lightweight Bash environement and a heightweight one, not
[Bash on Ubuntu on Windows](https://msdn.microsoft.com/en-us/commandline/wsl/about)

### Git-Bash 
You can download it from [Git-Bash](https://git-scm.com/downloads).

Install it, then configure it via [setup-bash.sh](https://raw.githubusercontent.cn/junjiemars/kit/master/ul/setup-bash.sh)

* Shortcut: 
```
Target: "C:\Program Files\Git\usr\bin\mintty.exe"
Start in: "%USERPROFILE%"
```
* Configure Bash environement:
```sh
bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)
```

### Bash in Docker 
Pull docker images or build from dockerfile, see [Kit for Docker](https://raw.githubusercontent.com/junjiemars/kit/master/docker/README.md)

## Encoding

### Command Prompt
* Mannually
```bat
REM unicode:65001, OEM(US):437, OEM(GBK):936
chcp 65001
```
* Registry
```bat
REM change value from:
HKEY_LOCAL_MACHINE\Software\Microsoft\Command Processor\Autorun
REM to:
@chcp 65001>nul
```
