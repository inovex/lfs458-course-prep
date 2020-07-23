#!/usr/bin/env bash

# A simple helper script to ssh into the master node of one of the students
set -eo pipefail

# Helper method to create the select menu from the array
# Inspired by: https://linuxhint.com/bash_select_command/
menu_from_array ()
{
    select item; do
        # Check the selected menu item number
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ];
        then
            student=$item
            break;
        else
            echo "Wrong selection: Select any number from 1-$#"
        fi
    done
}

declare -a students
for file in ips/*;
do
    student=$(basename "${file}")
    students+=("${student%.*}")
done

menu_from_array "${students[@]}"

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# fetch first ip address
ip=$(head -n 1 "${scriptLocation}/../ips/${student}.txt" | awk -F' ' '{print $2}')
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i "keys/${student}" "student@${ip}"
