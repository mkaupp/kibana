#!/bin/bash

while getopts g:r:h:x:c:t: option
do
case "${option}"
in
h) GIT_HEAD=${OPTARG};;
r) RUN_COUNT=${OPTARG};;
d) PACKET_DELAY=${OPTARG};;
g) GREP=${OPTARG};;
x) XPACK=${OPTARG};;
c) CHERRY_PICKS=${OPTARG};;
t) THROTTLED=${OPTARG};;
esac
done

if [ "$RUN_COUNT" = "" ]
then
  RUN_COUNT=1
fi

if [ "$PACKET_DELAY" = "" ]
then
  PACKET_DELAY=0
#	sudo /sbin/tc qdisc del dev lo root
# sudo /sbin/tc qdisc add dev lo root netem delay ${PACKET_DELAY}ms
fi

throttle=""
if [ "$THROTTLED" != "" ]
then
 echo "Throttling is ON"
 throttle="true"
else
 echo "Throttling is OFF"
fi

cd /home/gammon/kibana
echo "Fetching upstream"
git fetch upstream

regExpHeadCommit="HEAD is now at ([a-zA-Z0-9]+) (.*) (\(#([0-9]+)\))?"
gitHeadLine=
gitHash=
prNumber=
gitDescription=

echo "Syncing to ${GIT_HEAD}"

lines=$(git reset --hard ${GIT_HEAD})

if [[ "$lines" =~ $regExpHeadCommit ]]
then
  gitHash="${BASH_REMATCH[1]}"
  gitDescription="${BASH_REMATCH[2]}"
  prNumber="${BASH_REMATCH[4]}"
  echo "Hash: ${gitHash} description: ${gitDescription} prNumber: ${prNumber}"
fi

gitDate=`git show -s --format=%cI ${gitHash}`

if [ "$gitDescription" = "" ]; then
  echo "Something went wrong, no description found: ${gitDescription}"
  exit;
fi

# Cherrypicks that stabilize flaky tests.
#sudo git cherry-pick e85bbf4

# Changes to track all test times and full test title
#sudo git cherry-pick 1677685

# Changes to extend leadfoot timeouts to enable testing slow internet connections
#sudo git cherry-pick 9c4fbd5

for cherry in $CHERRY_PICKS; do
  echo "sudo git cherry-pick ${cherry}"                                                              
  git cherry-pick ${cherry}                                                                                        
done

export NODE_OPTIONS="--max_old_space_size=4096"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
 
 ~/.nvm/nvm.sh
echo "Using latest NVM"
nvm use

echo "Deleting es directory"
rm -rf .es
echo "Running clean && bootstrap"
yarn kbn clean && yarn kbn bootstrap
node scripts/build_kibana_platform_plugins

logstashTracking="PACKET_DELAY:${PACKET_DELAY} GIT_HEAD:${GIT_HEAD} GIT_HASH:${gitHash} DESCRIPTION:\"${gitDescription}\" GIT_DATE:${gitDate}"

if [ "$prNumber" != "" ]; then
 logstashTracking="${logstashTracking} PR:${prNumber}"
fi
 
cd ../benchmark
echo "Running benchmark, throttle is ${throttle}, runcount is ${RUN_COUNT}"
./benchmark.sh -t "${throttle}" -g "${GREP}" -r ${RUN_COUNT} -a "${logstashTracking}" -x ${XPACK}
