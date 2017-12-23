# IDE


* [Emacs](#emacs)
* [Vim](#vim)
* [Intellij IDEA](#intellij-idea)
* [Visual Studio Code](#visual-studio-code)
* [SQLDeveloper](#sqldeveloper)


## Emacs


## Vim


## IntelliJ IDEA 


### Import/Export Settings

```sh
# import settings
idea-jar-kit -a=<where-to-save-settings.jar>
# via Idea `import settings...'
```

```sh
# export settings
idea-jar-kit -x=<where-idea-exported-settings.jar>
```


### Settings

* switch IDE boot JDK: ```[M-x switch IDE boot JDK]```
* project JDK: ```[C-S-x s]```
* console font: ```Settings > Editor > Colors & Fonts > Console Font```


### External Tools

Use _Emacs_ as external editor, at ```Settings > Tools > External Tools```:
* Program: ```<where-emacsclient>```
* Parameters: ```-c $LineNumber$:$ColumnNumber$ $FilePath$```
* Working directory: ```$FileDir$```

Then start _Emacs_ as ```daemon``` or eval ```(server-start)``` after run.



## Visual Stuido Code

* Keep default platform specific settings and keyboard shortcuts;
* Using Emacs keys for basic commands;
* Using Vim keys for editing;

### Basic Commands

| command                            | keys           |
|:-----------------------------------|:---------------|
| add folder into workspace          | C-x d          |
| close workspace                    |                |
| open untitled file                 | C-x C-f        |
| switch buffer (quick open)         | C-x b          |
| close active editor                | C-x k          |
| open next editor                   | C-tab          |
| open previous editor               | C-S-tab        |
| run command (show command)         | M-x            |
| view explorer                      | C-x C-b        |
| view debug                         | C-x C-d        |
| view git                           | C-x C-g        |
| view search                        | C-x C-s        | 
| toggle sidebar                     |                |
| focus \<n\>th editor group         | C-\<n\>        |
| toggle integrated terminal         | C-`            |
| focus integrated terminal          | C-0 `          |
| switch integrated terminal         | C-9 `          |
| focus active editor group          | C-0 ~          |
| toggle panel                       |                |
| show hover                         | C-h d          |



## SQLDeveloper


