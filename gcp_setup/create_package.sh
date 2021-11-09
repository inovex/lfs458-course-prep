#!/usr/bin/env bash
set -eu

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export DEST="./packages"

rm -rf "${DEST}"
mkdir -p "${DEST}"

for f in ips/*;
do
  FILENAME="$(basename "$f")"
  FILENAME=${FILENAME%.*}
  echo "Create package for ${FILENAME}"
  puttygen "./keys/${FILENAME}" -O private -o "keys/${FILENAME}.ppk"
  zip "${DEST}/${FILENAME}.zip" "./keys/${FILENAME}" "./keys/${FILENAME}.ppk" "./ips/${FILENAME}.txt"
done
