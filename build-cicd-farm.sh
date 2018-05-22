#!/usr/bin/env bash

export config=/etc/jenkins_jobs/config/jenkins-conf.yml
export FName=CICD-Build
export SCRIPT_NAME=cicd-install-jenkins.sh

# clean up first
rm base.json

# create base script file
cat <<EOF >> base.json
{
   "timeoutDefault": 1,
   "description": "",
   "tags": [],
   "deprecated": false,
   "blockingDefault": true,
   "osType": "linux",
   "name": "$SCRIPT_NAME"
 }
EOF

scriptid=$(scalr-ctl --config $config scripts list | jq ".data[] | select(.name==\"$SCRIPT_NAME\").id")

if [ -z "$scriptid" ]
then
  echo "create base script"
  scriptid=$(scalr-ctl --config $config scripts create --stdin < base.json | jq .data.id)
fi

# get id
echo $scriptid

# convert script to json
export body=$(python -c 'import os, sys, json; y=open(os.environ["SCRIPT_NAME"], "r").read(); print json.dumps(y)')

# clean up files
rm $SCRIPT_NAME.json

# create import file
cat <<EOF >> $SCRIPT_NAME.json
{
  "body": $body
}
EOF

# create script version
scalr-ctl --config $config script-versions create --scriptId $scriptid --stdin < $SCRIPT_NAME.json

# Create farm and get ID
export farm_template=$FName.json
cat jenkins-farm.json  | jq '.farm.name=env.FName' > $farm_template
export farmid=`scalr-ctl --config $config farms create-from-template --stdin < $farm_template | jq '.data.id'`
echo $farmid

# launch farm
scalr-ctl --config $config farms launch --farmId $farmid

#give scalr time to kick off
sleep 60

# get server id
scalr-ctl --config $config farms list-servers --farmId $farmid
export serverid=`scalr-ctl --config $config farms list-servers --farmId $farmid | jq '.data[0].id'|tr -d '"'`
export orchserverid='"'$serverid'"'

echo $serverid
echo $orchserverid

# loop till the server is up and running
while [ "$serverstatus" != "running" ]
 do echo "Status: $serverstatus"
	export serverstatus=`scalr-ctl --config $config servers get --serverId $serverid | jq '.data.status'| tr -d '"'`
	sleep 30
done

echo "waiting 5 mins for the scripts to finish"

# sleep 300 to give scalr time to run scripts
sleep 300

# get orchestration log id
export orchlogid=`scalr-ctl --config $config scripts list-orchestration-logs | jq ".data[] | select(.server.id | contains($orchserverid)).id"| sed "s/\"//g"`

# get orchestration logs
scalr-ctl --config $config scripts get-orchestration-log --logEntryId $orchlogid | jq '.'

# verify exit code
if [ `scalr-ctl --config $config scripts get-orchestration-log --logEntryId $orchlogid | jq '.data.executionExitCode'` != 0 ]
 then
 exit 1
fi
