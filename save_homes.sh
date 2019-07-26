#!/bin/bash

set -eu

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

dest=${scriptLocation}/homes
mkdir -p ${dest}

function ipOf() {
   local student=${1}
   local node=${2}
   cat ${scriptLocation}/ips/${student} | grep ${node} | awk '{ print $2 }'
}

for student in $(find ips -type f -exec basename {} \;) ; 
do 
   tmpDir=$(mktemp -d)
   mkdir  ${tmpDir}/master
   scp -o StrictHostKeyChecking=no -r -i ${scriptLocation}/keys/${student} student@$(ipOf ${student} master):/home/student ${tmpDir}/master || echo "some files might be missing for ${student} master"
   mkdir ${tmpDir}/node
   scp -o StrictHostKeyChecking=no -r -i ${scriptLocation}/keys/${student} student@$(ipOf ${student} node):/home/student ${tmpDir}/node || echo "some files might be missing for ${student} node"
   zip -r ${dest}/${student}_home.zip ${tmpDir}
   rm -rf ${tmpDir}
done
