#!/usr/bin/env bash

set -euo pipefail

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for student in "${scriptLocation}"/../ips/*;
do
    # We can ignore this warning here since we never write to this file
    # shellcheck disable=SC2094
    while read -r ip;
    do
        echo "Validate $ip for student $(basename "$student")"
        ssh -q -n -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i "keys/$(basename "$student")" "student@$ip" -- echo success
    done < "$student"
done
