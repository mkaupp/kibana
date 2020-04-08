#!/bin/bash

while getopts c:d:g:h:r:t:x: option; do
  case "${option}" in

  c) CHERRY_PICKS=${OPTARG} ;;
  d) PACKET_DELAY=${OPTARG} ;;
  g) GREP=${OPTARG} ;;
  h) GIT_HEAD=${OPTARG} ;;
  r) RUN_COUNT=${OPTARG} ;;
  t) THROTTLED=${OPTARG} ;;
  x) XPACK=${OPTARG} ;;

  esac
done

throttle=""
setDefaults() {
  if [ "$RUN_COUNT" = "" ]; then
    RUN_COUNT=1
  fi

  if [ "$PACKET_DELAY" = "" ]; then
    PACKET_DELAY=0
  #	sudo /sbin/tc qdisc del dev lo root
  # sudo /sbin/tc qdisc add dev lo root netem delay ${PACKET_DELAY}ms
  fi
  if [ "$THROTTLED" != "" ]; then
    throttle="true"
  fi

}
setDefaults

printInitVars() {
  echo "### GIT_HEAD: ${GIT_HEAD}"
  echo "### RUN_COUNT: ${RUN_COUNT}"
  echo "### PACKET_DELAY: ${PACKET_DELAY}"
  echo "### GREP: ${GREP}"
  echo "### XPACK: ${XPACK}"
  echo "### CHERRY_PICKS: ${CHERRY_PICKS}"
  echo "### THROTTLED: ${THROTTLED}"
}
printInitVars

changeDirToRoot() {
  pushd ../../../../
}
changeDirToRoot

fetchOrigin() {
  echo "### Fetching origin"
  git fetch origin
}
fetchOrigin

regExpHeadCommit="HEAD is now at ([a-zA-Z0-9]+) (.*) (\(#([0-9]+)\))?"
gitHeadLine=
gitHash=
prNumber=
gitDescription=

resetGit() {
  echo "### Syncing to GIT_HEAD: ${GIT_HEAD}"
  lines=$(git reset --hard ${GIT_HEAD})
}
resetGit
#lines="HEAD is now at 00507bd288 Run it"
echo "### lines: ${lines}"

parseGit() {
  # https://unix.stackexchange.com/a/340485
  # performs a regular expression match of the string to its left,
  # to the extended regular expression on its right.
  if [[ "$lines" =~ $regExpHeadCommit ]]; then
    gitHash="${BASH_REMATCH[1]}"
    gitDescription="${BASH_REMATCH[2]}"
    prNumber="${BASH_REMATCH[4]}"
    echo "### gitHash: ${gitHash}"
    echo "### gitDescription: ${gitDescription}"
    echo "### prNumber: ${prNumber}"
  fi

  # Note:
  # *** BASH_REMATCH ***
  # An array variable whose members are assigned by the ‘=~’ binary operator to the
  # [[ conditional command (see Conditional Constructs).
  # The element with index 0 is the portion of the string matching the entire regular expression.
  # The element with index n is the portion of the string matching the nth parenthesized subexpression.
  # This variable is read-only.
}
parseGit

maybeExit() {
  if [ "$gitDescription" = "" ]; then
    echo "### Something went wrong, no description found, gitDescription: [${gitDescription}]"
    exit 1
  fi
}
maybeExit

gitDate=$(git show -s --format=%cI ${gitHash})
echo "### gitDate: ${gitDate}"

## Cherrypicks that stabilize flaky tests.
##sudo git cherry-pick e85bbf4
#
## Changes to track all test times and full test title
##sudo git cherry-pick 1677685
#
## Changes to extend leadfoot timeouts to enable testing slow internet connections
##sudo git cherry-pick 9c4fbd5
#
#for cherry in $CHERRY_PICKS; do
#  echo "sudo git cherry-pick ${cherry}"
#  git cherry-pick ${cherry}
#done
#
#export NODE_OPTIONS="--max_old_space_size=4096"
#
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
#
#~/.nvm/nvm.sh
#echo "Using latest NVM"
#nvm use
#
#echo "Deleting es directory"
#rm -rf .es
#echo "Running clean && bootstrap"
#yarn kbn clean && yarn kbn bootstrap
#node scripts/build_kibana_platform_plugins
#
#logstashTracking="PACKET_DELAY:${PACKET_DELAY} GIT_HEAD:${GIT_HEAD} GIT_HASH:${gitHash} DESCRIPTION:\"${gitDescription}\" GIT_DATE:${gitDate}"
#
#if [ "$prNumber" != "" ]; then
#  logstashTracking="${logstashTracking} PR:${prNumber}"
#fi
#
#cd ../benchmark
#echo "Running benchmark, throttle is ${throttle}, runcount is ${RUN_COUNT}"
#./benchmark.sh -t "${throttle}" -g "${GREP}" -r ${RUN_COUNT} -a "${logstashTracking}" -x ${XPACK}
