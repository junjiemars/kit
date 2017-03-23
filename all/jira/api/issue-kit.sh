#!/bin/bash 



HELP=
VERBOSE=
DUMP_HEADER=
IPV6=${IPV6:-"-4"}
COMMAND=${COMMAND:-"CREATE"}
HOST=${HOST:-"localhost"}
PORT=${PORT:-"8080"}
JIRA_USER=
PROJECT=
SIZE=1
JSON_DIR=${JSON_DIR:-"`pwd`"}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] [COMMANDS] [ARGUMENTS...]\n"

  echo -e "Options:"
  echo -e "  --help\t\tPrint this message"
  echo -e "  --verbose\t\tVerbose output"
  echo -e "  --dump-header\t\tDump http header\n"

  echo -e "Commands:"
  echo -e "  --op=create\t\tCreate issues"
  echo -e "  --op=meta\t\tQuery API's meta\n"

  echo -e "Arguments:"

  echo -e "  --host\t\tJira's host address, default is localhost"
  echo -e "  --port\t\tJira's port number, default is 8080\n"
  echo -e "  --user\t\tJira's login account, <username>:<passwd>, required"
  echo -e "  --project\t\tJira's project key, case sensitive, required"
  echo -e "  --size\t\tIssues count, default is 1, >=1"
  echo -e "  --json-dir\t\tJson tepmlate dir, default is current working dir"
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                          HELP=YES                   ;;
    --verbose)                       VERBOSE="-v"               ;;
    --dump-header)                   DUMP_HEADER="-D-"          ;;
    
    --host=*)   	                   HOST="$value"     				  ;;
    --post=*)   	                   PORT="$value"     				  ;;

    --op=*) 	                   		 COMMAND="$value"      			;;
    --user=*)   	                   JIRA_USER="$value"    			;;
    --project=*)                     PROJECT="$value"     	    ;;
    --size=*)                     	 SIZE="$value"     	    		;;
    --json-dir=*)                    JSON_DIR="$value"       		;;
    
    *)
      echo "$0 [error]: invalid option \"$option\"\n"
			usage
      exit 1
    ;;
  esac
done


if [ "YES" = "$HELP" -o 0 -eq $# ]; then
	usage
	exit 0
fi


if [ "x" = "x${JIRA_USER}" ]; then
	echo -e "$0 [error]: missing --user= argument\n"
	usage
	exit 1
fi


if [ "x" = "x${PROJECT}" ]; then
	echo -e "$0 [error]: missing --project= argument\n"
	usage
	exit 1
else
	PROJECT="`echo ${PROJECT} | tr [:lower:] [:upper:]`"
fi


JSON_FILE="${JSON_DIR%/}/create_issue_${PROJECT}.json"
JIRA_ISSUE_URL="http://${HOST}:${PORT}/jira/rest/api/2/issue"
CURL_H="Content-Type: application/json"
CURL_M=

COMMAND="`echo $COMMAND | tr [:lower:] [:upper:]`"
case "$COMMAND" in
	CREATE)
		if [ "x" = "x${SIZE}" -o $SIZE -lt 1 ]; then
			echo -e "$0 [error]: missing --size= argument or less than 1\n"
			usage
			exit 1
		fi
		CURL_M="POST"
		if [ ! -f "$JSON_FILE" ]; then
			echo -e "$0 [error]: ${JSON_FILE} no found"
			exit 1
		fi
		for i in $(seq 1 $SIZE); do
			echo -e "\n"
			curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" -d@"$JSON_FILE" $JIRA_ISSUE_URL
		done
		echo -e "\n"
		;;
	META)
		CURL_M="GET"
		JIRA_META="createmeta?projectKeys=$PROJECT"
		JIRA_FIELDS="&expand=projects.issuetypes.fields"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}${JIRA_FIELDS}"
		echo -e "\n"
		;;
	*)
		echo -e "$0 [error]: invalid --op= argument\n"
		usage
		exit 1
		;;
esac



