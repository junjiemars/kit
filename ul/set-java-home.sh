os=$(uname -s)
if [ ${os} = "darwin" ]; then
    export JAVA_HOME=$(/usr/libexec/java_home)
elif [ ${os} = "linux" ]; then
    export JAVA_HOME=$(readlink -f `type -p java`|sed 's:/bin/java::g')
fi

