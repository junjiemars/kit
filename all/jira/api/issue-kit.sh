#!/bin/bash 



HELP=
VERBOSE=
DUMP_HEADER=
DRY_RUN=NO
API_DOC=NO
API_DOC_URL='https://docs.atlassian.com/jira/REST/5.0.6/'

IPV6=${IPV6:-"-4"}
COMMAND=${COMMAND:-"CREATE"}
HOST=${HOST:-"localhost"}
PORT=${PORT:-"8080"}
JIRA_USER=
PROJECT=
SIZE=1
ISSUE_ID=
ISSUE_ID_P=
ISSUE_KEY_P=
ISSUE_ID_RANGE=
JSON_DIR=${JSON_DIR:-"`pwd`"}
JSON_RAW=
TRANSITION_ID=
TRANSITION_ID_RANGE=
PROPERTY_ID=

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] [COMMANDS] [ARGUMENTS...]\n"
  echo -e "A tiny tool of Jira' API, using --op=*-meta commands check first, then use --op=* commands\n"

  echo -e "Options:"
  echo -e "  --help                 Print this message"
  echo -e "  --verbose              Verbose output"
  echo -e "  --dump-header          Dump http header"
  echo -e "  --dry-run              perform a trial run with no changes made"
  echo -e "  --api-doc              Jira's offical online API's doc\n"

  echo -e "Commands:"
  echo -e "  --op=create            Create issues"
  echo -e "  --op=create-meta       Query API's create meta"
  echo -e "  --op=edit-meta         Query API's edit meta, need check issue-id<N> first"
  echo -e "  --op=transit-meta      Query API's transition meta"
  echo -e "  --op=delete            Delete issue and subtasks, need privileges"
  echo -e "  --op=query             Query issue, need issue-id<KEY>"
  echo -e "  --op=app-meta          Query application properties, need privileges\n"

  echo -e "Arguments:"

  echo -e "  --host                 Jira's host address, default is localhost"
  echo -e "  --port                 Jira's port number, default is 8080\n"
  echo -e "  --user                 Jira's login account, <username>:<passwd>, required\n"
  echo -e "  --project              Jira's project key, case insensitive"
  echo -e "  --issue-id             Jira's issue <ID>s or <KEY>s, case insensitive, <id1,id2, ...>"
  echo -e "  --size                 Issues count, default is 1"
  echo -e "  --trainsition-id       Issues trainsition's state <id>, <id1, id2, ...>"
  echo -e "  --property-id          Jira's property id <ID>s or <KEY>s, case insensitive, <id1,id2, ...>"
  echo -e "  --json-dir             Json tepmlate dir, default is current working dir"
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                          HELP="YES"                 ;;
    --verbose)                       VERBOSE="-v"               ;;
    --dump-header)                   DUMP_HEADER="-D-"          ;;
    --dry-run)                       DRY_RUN="YES"              ;;
    --api-doc)                       API_DOC="YES"              ;;
    
    --host=*)   	                   HOST="$value"     				  ;;
    --post=*)   	                   PORT="$value"     				  ;;

    --op=*) 	                   		 COMMAND="$value"      			;;
    --user=*)   	                   JIRA_USER="$value"    			;;
    --project=*)                     PROJECT="$value"     	    ;;
    --issue-id=*)                    ISSUE_ID="$value"     	    ;;
    --size=*)                     	 SIZE="$value"     	   			;;
    --transition-id=*)               TRANSITION_ID="$value"    	;;
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

if [ "YES" = "$API_DOC" ]; then
	echo "$API_DOC_URL"
	exit 0
fi

function check_option() {
	local arg_name=$1
	local arg_value=$2 
	local need_usage=$3

	if [ "x" = "x${arg_value}" ]; then
		echo -e "$0 [error]: missing --${arg_name}= argument\n"
		[ 1 -eq $need_usage ] || usage
		return 1
	else
		return 0
	fi
}


if ! `check_option "JIRA_USER" "${JIRA_USER}" 1`; then
	exit 1
fi


JIRA_FILE=
JIRA_URL="http://${HOST}:${PORT}/jira/rest/api/2"
JIRA_ISSUE_URL="${JIRA_URL}/issue"
CURL_H="Content-Type: application/json"
CURL_M=

COMMAND="`echo $COMMAND | tr [:lower:] [:upper:]`"
case "$COMMAND" in
	CREATE)
		check_option "project" "${PROJECT}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			PROJECT="`echo ${PROJECT} | tr [:lower:] [:upper:]`"
		fi
		
		if [ 0 -ne $(check_option "size" "${SIZE}" 1; echo $?) -o $SIZE -lt 1 ]; then
			echo -e "$0 [error]: missing --size= argument or less than 1\n"
			usage
			exit 1
		fi

		JSON_FILE="${JSON_DIR%/}/create_issue_${PROJECT}.json"
		CURL_M="POST"
		if [ ! -f "$JSON_FILE" ]; then
			echo -e "$0 [error]: ${JSON_FILE} no found"
			exit 1
		fi

		for i in $(seq 1 $SIZE); do
			echo -e "\n"
			if [ "YES" = "$DRY_RUN" ]; then
				echo curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" -d@"$JSON_FILE" $JIRA_ISSUE_URL
			else
				curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" -d@"$JSON_FILE" $JIRA_ISSUE_URL
			fi
			echo -e "\n"
		done
		;;
	CREATE-META)
		check_option "project" "${PROJECT}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			PROJECT="`echo ${PROJECT} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="GET"
		JIRA_META="createmeta?projectKeys=$PROJECT"
		JIRA_FIELDS="&expand=projects.issuetypes.fields"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}${JIRA_FIELDS}"
		echo -e "\n"
		;;
	EDIT-META)
		check_option "issue-id" "${ISSUE_ID}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="GET"
		JIRA_META="$ISSUE_ID/editmata"
		if [ "YES" = "$DRY_RUN" ]; then
			echo curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
		else
			echo -e "\n"
			curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
			echo -e "\n"
		fi
		;;
	TRANSIT-META)
		check_option "issue-id" "${ISSUE_ID}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="GET"
		JIRA_META="$ISSUE_ID/transitions?expand=transitions.fields"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
		echo -e "\n"
		;;
	DELETE)
		check_option "issue-id" "${ISSUE_ID}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="DELETE"
		IFS=',' read -a ISSUE_ID_RANGE <<< "$ISSUE_ID"
		for i in "${ISSUE_ID_RANGE[@]}"; do
			echo $i
			JIRA_META="${i}?deleteSubtasks=true"
			echo -e "\n"
			if [ "YES" = "$DRY_RUN" ]; then
				echo curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
			else
				curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
			fi
			echo -e "$0 [DELETE: $?K]\n"
		done
		;;
	TRANSIT)
		check_option "issue-id" "${ISSUE_ID}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="POST"
		IFS=',' read -a ISSUE_ID_RANGE <<< "$ISSUE_ID"
		for i in "${ISSUE_ID_RANGE[@]}"; do
			JIRA_META="${i}/transitions"
			IFS=',' read -a TRANSITION_ID_RANGE <<< "$TRANSITION_ID"
			echo "$TRANSITION_ID_RANGE"
			for j in "${TRANSITION_ID_RANGE[@]}"; do
				JSON_RAW="{\"transition\":{\"id\":"${j}"}}"
				echo -e "\n"
				if [ "YES" = "$DRY_RUN" ]; then
					echo curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" -d"$JSON_RAW" "$JIRA_ISSUE_URL/${JIRA_META}"
				else
					curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" -d"$JSON_RAW" "$JIRA_ISSUE_URL/${JIRA_META}"
				fi
				echo -e "$0 [TRANSIT: $?K]: => ${j}\n"
			done
		done
		;;
	QUERY)
		check_option "issue-id" "${ISSUE_ID}" 1
		if [ 0 -ne $? ]; then
			exit 1
		else
			ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"
		fi

		CURL_M="GET"
		JIRA_META="$ISSUE_ID"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
		echo -e "\n"
		;;
	APP-META)
		CURL_M="GET"
		JIRA_META="application-properties"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_URL/${JIRA_META}"
		echo -e "\n"
		;;
	*)
		echo -e "$0 [error]: invalid --op= argument\n"
		usage
		exit 1
		;;
esac

