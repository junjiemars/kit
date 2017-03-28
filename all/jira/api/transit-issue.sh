#!/bin/bash


JIRA_PROJECT=${JIRA_PROJECT:-"`echo $1 | tr [:lower:] [:upper:]`"}
JIRA_USERS=${JIRA_USERS:-"`cat transit_user_${JIRA_PROJECT}.txt`"}
JIRA_ISSUES=${JIRA_ISSUES:-"`cat transit_issue_${JIRA_PROJECT}.txt | tr [:lower:] [:upper:] | tr -d ' '`"}
INTERVAL=${INTERVAL:-0}


echo "#JIRA_PROJECT=>$JIRA_PROJECT"
echo "#JIRA_USERS=>$JIRA_USERS"
echo "#JIRA_ISSUES=>$JIRA_ISSUES"

IFS=';' read -a JIRA_UTS <<< "$JIRA_USERS"
IFS=',' read -a JIRA_IDS <<< "$JIRA_ISSUES"

for id in "${JIRA_IDS[@]}"; do

	for ut in "${JIRA_UTS[@]}"; do
		IFS='|' read -a JIRA_UT <<< "$ut"
		echo "#TRANSIT# ${id} => ${JIRA_UT[1]} <= ${JIRA_UT[0]}"	

		./issue-kit.sh --user="${JIRA_UT[0]}" --op=transit --issue-id="$id"	--transition-id="${JIRA_UT[1]}"
		sleep $INTERVAL
		#echo -user="${JIRA_UT[0]}" --issue-id="$id"	--transition-id="${JIRA_UT[1]}"

	done

done
