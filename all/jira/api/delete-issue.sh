#!/bin/bash


JIRA_PROJECT=${JIRA_PROJECT:-"`echo $1 | tr [:lower:] [:upper:]`"}
JIRA_USER=${JIRA_USER:-""}
JIRA_ISSUES=${JIRA_ISSUES:-"`cat delete_issue_${JIRA_PROJECT}.txt | tr [:lower:] [:upper:] | tr -d ' '`"}
INTERVAL=${INTERVAL:-0}


echo "#JIRA_PROJECT=>$JIRA_PROJECT"
echo "#JIRA_USER=>$JIRA_USER"
echo "#JIRA_ISSUES=>$JIRA_ISSUES"
echo -e "====================\n"

IFS=',' read -a JIRA_IDS <<< "$JIRA_ISSUES"
if [ -z "${JIRA_USER}" -o 0 -eq ${#JIRA_IDS[@]} ]; then
	echo "$0 [error]: empty JIRA_USER or JIRA_ISSUES, nothing to be done"
	exit 1
fi

for id in "${JIRA_IDS[@]}"; do

	echo "#DELETE# ${id} <= ${JIRA_USER}"	
	
	./issue-kit.sh --user="${JIRA_USER}" --op=delete --issue-id="$id"	
	#echo --user="${JIRA_USER}" --op=delete --issue-id="$id"	
	sleep $INTERVAL


done
