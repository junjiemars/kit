# Kit for Windows

* [Bash Environment](#bash-environment)
  * [Git-Bash](#git-bash)
  * [Bash in Docker](#bash-in-docker)
* [Encoding](#encoding)
* [Emacs](#emacs)
* [PsTools](#pstools)


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

## Emacs
Install and setup [Emacs](https://www.gnu.org/software/emacs/) on Windows needs some tricks: the samed behaviors, keybindings, styles on Windows just like on Linux or Darwin.
On Windows, Emacs always missing some libraries, such zlib, gnutls, etc.

But the following handy kits do it all for you:
```sh
$ cd && git clone --depth=1 --branch=master https://github.com/junjiemars/.emacs.d.git
$ bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)
$ . ~/.bashrc
$ HAS_EMACS=1 bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/win/install-win-kits.sh)
```

I'd not found a effective way to get/set user specific PATH environment in Bash, sadly we need 
set the PATH for Emacs by hand via **Advanced System Settings > Environment Variables > User Variables**
* Set EMACS_HOME to $OPT_RUN/emacs
* Append %EMACS_HOME%\bin to PATH
* Append %EMACS_HOME%\lib to PATH

## PsTools
[PsTools](https://technet.microsoft.com/en-us/sysinternals/pstools.aspx) is very handy and powerful tools on Windows written 
by [Mark Russinovich](https://en.wikipedia.org/wiki/Mark_Russinovich) since in [Sysinternals](https://en.wikipedia.org/wiki/Sysinternals).
And it very easy to use:
```sh
$ HAS_PSTOOL=1 bash <(curl https:/raw.githubusercontent.com/junjiemars/kit/master/win/install-win-kits.sh)
$ . ~/.bashrc
$ pslist
```

Set PsTools environment variables by hand, the reason is samed with [Emacs](#emacs):
* Set PSTOOLS_HOME to $OPT_RUN/pstools
* Append %PSTOOLS_HOME% to PATH