#!/bin/bash
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS
set -eu

# LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
#   while read snapname revision; do
#     sudo snap remove "$snapname" --revision="$revision"
#   done


snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then snap remove "$snapname" --revision="$rev"; fi; done

snap_remove_disabled () {
  LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
      sudo snap remove "$snapname" --revision="$revision"
    done
}
