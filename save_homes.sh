#!/bin/bash

set -eu

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

dest=${scriptLocation}/homes
mkdir -p ${dest}

function ipOf() {
   local student=${1}
   local node=${2}
   cat ${scriptLocation}/ips/${student} | grep -e "^${node}:" | awk '{ print $2 }'
}

function download() {
   local student=${1}
   tmpDir=$(mktemp -d)
   for n in master node proxy "second-master" "third-master"; do
   	mkdir -p  "${tmpDir}/${n}"
   	scp -q -o StrictHostKeyChecking=no -r -i ${scriptLocation}/keys/${student} student@$(ipOf ${student} ${n}):/home/student "${tmpDir}/${n}" || echo "some files might be missing for ${student} ${n}"
   done
   zip -q -r ${dest}/${student}_home.zip ${tmpDir}
   rm -rf ${tmpDir}
}

for student in $(find ips -type f -exec basename {} \;) ; 
do 
   download ${student} &
done

wait
