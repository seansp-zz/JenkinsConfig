#!/bin/bash

## Get my Crumb.
CRUMB=$(curl -s -u $1:$2 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
JENKINS=$(echo "http://localhost:8080")

## Install the plugins

curl -X POST -d '<jenkins><install plugin="startup-trigger-plugin@2.9.3"  /></jenkins>' -H "Content-Type:text/xml" -u $1:$2 -H $CRUMB $JENKINS/pluginManager/installNecessaryPlugins

pushd ~jenkins/plugins
sudo wget http://updates.jenkins-ci.org/download/plugins/powershell/1.3/powershell.hpi
popd
 




## Add the nodes.
sudo mkdir ~jenkins/nodes/hgs
sudo cp ./nodes/hgs.xml ~jenkins/nodes/hgs/config.xml
sudo mkdir ~jenkins/nodes/ghost
sudo cp ./nodes/ghost.xml ~jenkins/nodes/ghost/config.xml
sudo chown -R jenkins ~jenkins/nodes

## Add the job.
sudo mkdir ~jenkins/jobs/IsHostGuarded
sudo cp ./jobs/IsHostGuarded.xml ~jenkins/jobs/IsHostGuarded/config.xml
sudo chown -R jenkins ~jenkins/jobs

## Add the 'mstest' credential for the SSH connections.
## The id mstest is here for the nodes to know which credential to use.
curl -X POST 'http://localhost:8080/credentials/store/system/domain/_/createCredentials' -H $CRUMB --data-urlencode \
'json={
  "": "0",
  "credentials": {
    "scope":"GLOBAL",
    "id": "mstest",
    "username": "'$1'",
    "password": "'$2'",
    "description": "Credential for connecting to machines using SSH.",
    "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
  }
}' -u $1:$2

#Finally restart Jenkins.
sudo systemctl restart jenkins
echo "--- When Jenkins restarts, you should see IsGuardedHost running on the ghost node."
