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
  echo -e "A tiny tool of Jira' API, using *-meta commands check first, then use * commands\n"

  echo -e "Options:"
  echo -e "  --help                 Print this message"
  echo -e "  --verbose              Verbose output"
  echo -e "  --dump-header          Dump http header"
  echo -e "  --dry-run              perform a trial run with no changes made"
  echo -e "  --api-doc              Jira's offical online API's doc\n"

  echo -e "  --host                 Jira's host address, default is localhost"
  echo -e "  --port                 Jira's port number, default is 8080\n"
  echo -e "  --user                 Jira's login account, <username:passwd>, or <username1:passwd1,username2:passwd2,...>, required"
  echo -e "  --project              Jira's project key, case insensitive"
  echo -e "  --issue-id             Jira's issue <ID>s or <KEY>s, case insensitive, <id1,id2, ...>"
  echo -e "  --size                 Issues count, default is 1"
  echo -e "  --trainsition-id       Issues trainsition's state <id>, or <id1, id2, ...>"
  echo -e "  --property-id          Jira's property id <ID>s or <KEY>s, case insensitive, <id1,id2, ...>"
  echo -e "  --json-dir             Json tepmlate dir, default is current working dir\n"

  echo -e "Commands:"
  echo -e "  create                 Create issues"
  echo -e "  create-meta            Query API's create meta"
  echo -e "  edit-meta              Query API's edit meta, need check issue-id<N> first"
  echo -e "  transit                Transit states"
  echo -e "  transit-meta           Query API's transition meta"
  echo -e "  delete                 Delete issue and subtasks, need privileges"
  echo -e "  query                  Query issue, need issue-id<KEY>"
  echo -e "  app-meta               Query application properties, need privileges"
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

    --user=*)   	                   JIRA_USER="$value"    			;;
    --project=*)                     PROJECT="$value"     	    ;;
    --issue-id=*)                    ISSUE_ID="$value"     	    ;;
    --size=*)                     	 SIZE="$value"     	   			;;
    --transition-id=*)               TRANSITION_ID="$value"    	;;
    --json-dir=*)                    JSON_DIR="$value"       		;;

    *)
			COMMAND="$option"
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

check_required_option() {
	local arg_name=$1
	local arg_value=$2 
	local need_usage=$3

	if [ "x" = "x${arg_value}" ]; then
		echo "$0 [error]: missing ${arg_name}= option"
		[ 1 -eq $need_usage ] || usage
		return 1
	else
		return 0
	fi
}

check_option_empty() {
	local op_name="$1"
	local op_val="$2"	
	local op_a=()

	if [ -z "${op_val}" ]; then
		echo "$0 [error]: ${op_name}= empty size"	
		return 1
	fi

	IFS=',' read -a op_a <<< "$op_val"
	if [ 0 -eq ${#op_a[@]} ]; then
		echo "$0 [error]: ${op_name}= empty size"	
		return 1
	else 
		return 0
	fi
}

check_options_size_eq() {
	local op_lhs_name="$1"
	local op_lhs_val="$2"
	local op_rhs_name="$3"
	local op_rhs_val="$4"
	local lhss=()
	local rhss=()
	local t=0

	check_option_empty "$op_lhs_name" "$op_lhs_val"
	t=$?
	[ 0 -eq $t ] || return $t

	check_option_empty "$op_rhs_name" "$op_rhs_val"
	t=$?
	[ 0 -eq $t ] || return $t

	IFS=',' read -a lhss <<< "$op_lhs_val"
	IFS=',' read -a rhss <<< "$op_rhs_val"
	if [ ${#lhss[@]} -ne ${#rhss[@]} ]; then
		echo "$0 [error]: ${op_lhs_name}=${op_lhs_val} and ${op_rhs_name}=${op_rhs_val} mismatch"
		return 1
	else
		return 0
	fi	
}

create_template() {
	local p="$1"
	local f="$2"
	
	[ -n "$f" -a -f "$f" ] && return 0

	cat << END > "$f"
{
	"fields": {
		"project": {
			"id": "11700"
		},
		"summary": "ok, we missing it",
		"description": "some description",
		"issuetype": {
			"id": "118"
		},
		"customfield_11200": "<who>"
	}
}
END

	if [ -f "$f" ]; then
		echo "$0 [aux] create_issue_${p}.json template file had been created"
	fi
	return 1
}

check_required_option "--user" "${JIRA_USER}" 1
retval=$?
[ 0 -eq $retval ] || exit $retval


JIRA_FILE=
JIRA_URL="http://${HOST}:${PORT}/jira/rest/api/2"
JIRA_ISSUE_URL="${JIRA_URL}/issue"
CURL_H="Content-Type: application/json"
CURL_M=

COMMAND="`echo $COMMAND | tr [:lower:] [:upper:]`"
case "$COMMAND" in
	CREATE)
		check_required_option "--project" "${PROJECT}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		PROJECT="`echo ${PROJECT} | tr [:lower:] [:upper:]`"
		
		if [ 1 -gt $SIZE ]; then
			echo -e "$0 [error]: --size=${SIZE} should be greater or equal than 1\n"
			exit 1
		fi

		JSON_FILE="${JSON_DIR%/}/create_issue_${PROJECT}.json"
		CURL_M="POST"
		if [ ! -f "$JSON_FILE" ]; then
			echo -e "$0 [error]: ${JSON_FILE} no found"
			create_template "${PROJECT}" "${JSON_FILE}"
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
		check_required_option "--project" "${PROJECT}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		PROJECT="`echo ${PROJECT} | tr [:lower:] [:upper:]`"

		CURL_M="GET"
		JIRA_META="createmeta?projectKeys=$PROJECT"
		JIRA_FIELDS="&expand=projects.issuetypes.fields"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}${JIRA_FIELDS}"
		echo -e "\n"
		;;
	EDIT-META)
		check_required_option "--issue-id" "${ISSUE_ID}" 1
		[ 0 -eq $retval ] || exit $retval
		ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"

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
		check_required_option "--issue-id" "${ISSUE_ID}" 1
		retvall=$?
		[ 0 -eq $retval ] || exit $retval
		ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"

		CURL_M="GET"
		JIRA_META="$ISSUE_ID/transitions?expand=transitions.fields"
		echo -e "\n"
		curl $IPV6 $DUMP_HEADER $VERBOSE -u $JIRA_USER -X$CURL_M -H "$CURL_H" "$JIRA_ISSUE_URL/${JIRA_META}"
		echo -e "\n"
		;;
	DELETE)
		check_required_option "--issue-id" "${ISSUE_ID}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"

		check_option_empty "--issue-id" "${ISSUE_ID}"
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		
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
		check_required_option "issue-id" "${ISSUE_ID}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"

		check_required_option "transition-id" "${TRANSITION_ID}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval

		check_options_size_eq "--user" "$JIRA_USER" "--transition-id" "$TRANSITION_ID"
		retval=$?
		[ 0 -eq $retval ] || exit $retval

		CURL_M="POST"
		IFS=',' read -a USER_ID_RANGE <<< "$JIRA_USER"
		IFS=',' read -a TRANSITION_ID_RANGE <<< "$TRANSITION_ID"

		IFS=',' read -a ISSUE_ID_RANGE <<< "$ISSUE_ID"
		for i in "${ISSUE_ID_RANGE[@]}"; do
			JIRA_META="${i}/transitions"
			for ((u = 0; u < ${#USER_ID_RANGE[@]}; u++)); do
				IFS=':' read -a TRANSITION_ID_VAL <<< "${TRANSITION_ID_RANGE[${u}]}"
				if [ -n "$VERBOSE" ]; then
					echo "TRANSIT: ${USER_ID_RANGE[${u}]}'s ${TRANSITION_ID_VAL[@]}"
				fi
				for j in "${TRANSITION_ID_VAL[@]}"; do
					JSON_RAW="{\"transition\":{\"id\":"${j}"}}"
					echo -e "\n"
					if [ "YES" = "$DRY_RUN" ]; then
						echo curl $IPV6 $DUMP_HEADER $VERBOSE -u ${USER_ID_RANGE[${u}]} -X$CURL_M -H "$CURL_H" -d"$JSON_RAW" "$JIRA_ISSUE_URL/${JIRA_META}"
					else
						curl $IPV6 $DUMP_HEADER $VERBOSE -u ${USER_ID_RANGE[${u}]} -X$CURL_M -H "$CURL_H" -d"$JSON_RAW" "$JIRA_ISSUE_URL/${JIRA_META}"
					fi
					echo -e "$0 [TRANSIT: $?K]: => ${j}\n"
				done
			done
		done
		;;
	QUERY)
		check_required_option "issue-id" "${ISSUE_ID}" 1
		retval=$?
		[ 0 -eq $retval ] || exit $retval
		ISSUE_ID="`echo ${ISSUE_ID} | tr [:lower:] [:upper:]`"

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
		echo -e "$0 [error]: invalid command \"${COMMAND}\"\n"
		usage
		exit 1
		;;
esac

