#!/bin/bash
#------------------------------------------------
# wbd.sh:	web-deployment script
# author: 	junjiemars@gmail.com
# configure > stop > deploy > run web container
#------------------------------------------------
#echo "OPTIND starts at $OPTIND"
_d=0
_c="tomcat"
_t="./"
_w="./"
_p=8080
_s=8005
_incr_http=101
_incr_shutdown=100
_n=0
_g=0

_usage() {
	echo "usage: $(basename $0) [-h] [-c] {-t} [-w] [-p] [-s] [-n] [-i] [-k] [-g] [-d]"
	echo -e "\t-h help"
	echo -e "\t-c type of container, default:tomcat"
	echo -e "\t-t target root dir of container"
	echo -e "\t-w the path of war"
	echo -e "\t-p default http port:8080"
	echo -e "\t-s default shutdown port:8005"
	echo -e "\t-n node number of cluster? base on zero"
	echo -e "\t-i increment of cluster http port"
	echo -e "\t-k increment of cluster shutdown port"
	echo -e "\t-g go, 0:shutdown >0:startup"
	echo -e "\t-d debug flag"
}

_debug() {
	if [[ $_d -gt 0 ]]; then
		echo "$@"
	fi
}

_sha1() {
	echo `sha1sum $1|cut -d" " -f1`
}

_go_tomcat() {
	local t_=$1
	local p_=$2
	local s_=$3
	local g_=$4
	local w_=$5

	if [[ ! -f "$t_""bin/startup.sh" ]]; then
		_debug "# skip go, pwd:[$t_] is incorrect"
		return
	fi
	
	export CATALINA_BASE=$t_
	export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$p_ -Dshutdown.port=$s_"

	if [[ 0 -eq $(netstat -tln|grep $p_ 2>&1 1>/dev/null;echo $?) ]]; then
		_debug "# shutdown tomcat:$p_|$s_ [$CATALINA_BASE]..."
		echo $($CATALINA_BASE/bin/shutdown.sh)
		wait
		sleep 3

		if [ ! -z $w_ ] && [[ -f $w_ ]]; then
			local b_=$(basename $w_)
			local d_="$t_""webapps/"${b_%.*}
	
			if [[ -d $d_ ]]; then
				_debug "# rm dir:[$d_]..."
				if [[ 0 -ne $(rm -rf $d_ 2>/dev/null;echo $?) ]]; then
					_debug "# rm dir:[$d_] failed"
				fi
				wait
			else
				_debug "### dir no-exists:[$d_]"
			fi
		fi
	fi

	if [ ! -z $w_ ] && [[ -f $w_ ]]; then
		local f_="$t_""webapps/$(basename $w_)"	

		if [[ -f $f_ ]] && [ $(_sha1 $w_) = $(_sha1 $f_) ]; then
			_debug "# skip copy war:$p_|$s_, same war [sha1:$(_sha1 $f_)]"
		else
			if [[ 0 -ne $(cp $w_ $f_ 2>/dev/null;echo $?) ]]; then
				_debug "# skip go[$g_], copy war from [$w_] to [$f_] failed"	
				return
			fi
		fi
	fi	

	if [[ $g_ -gt 0 ]]; then
		_debug "# startup tomcat:$p_|$s_ [$CATALINA_BASE]..."
		echo $($CATALINA_BASE/bin/startup.sh)
		wait
	fi
}

_go() {
	local c_=$1
	local t_=$2
	local n_=$3
	local p_=$4
	local s_=$5
	local w_=$6

    case $c_ in
        tomcat) _debug "# go $c_:$p_|$s_ [g$_g] [$t_|$w_]...";
				if [[ 1 -gt $n_ ]]; then
					_go_tomcat $t_ $p_ $s_ $_g $w_
				else
					local f_=$(($p_+$_incr_http))
					local l_=$(($p_+$_incr_http*$(($n_+1))))
					local i_=0
	
					for p in `seq $f_ $_incr_http $l_`; do
						local b_="$t_""n$i_/"
						local k_=$(($s_+$_incr_shutdown*$i_))
						(_go_tomcat $b_ $p $k_ $_g $w_)
						let i_++
					done
				fi;;
        jetty) 	_debug "! unsupported";; 
        *)      _debug "! unsupported";;
    esac
}

if [[ $# -lt 1 ]]; then
	_usage
fi
	
while getopts "hc:t:w:s:p:n:i:k:g:d" optname; do
	case "$optname" in
		c) eval _c="$OPTARG";;
		t) eval _t="$OPTARG";;
		w) eval _w="$OPTARG";;
		s) eval _s="$OPTARG";;
		p) eval _p="$OPTARG";;
		n) eval _n="$OPTARG";;
		i) eval _incr_http="$OPTARG";;
		k) eval _incr_shutdown="$OPTARG";;
		g) eval _g="$OPTARG";;
		d) let _d++;;
		h) _usage;;
		?) _usage;;
		:) _usage;;
	esac
done

_debug -e "# calling args:[-c$_c -t$_t -w$_w -s$_s -p$_p -n$_n -i$_incr_http -k$_incr_shutdown -g$_g -d$_d]"

if [ -z $_t ] || [[ ! -d $_t ]]; then
	_debug "# target dir:[-t:$_t] is empty or no-exists, exiting..."
	exit $?
fi

_go $_c $_t $_n $_p $_s $_w

