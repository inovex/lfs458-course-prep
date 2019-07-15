#!/usr/bin/env bash
set -eu

# Find the script location. Inspired by: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
scriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export DEST="${scriptLocation}/packages"

rm -rf "${DEST}/*"
mkdir -p "${DEST}"

for f in ${@};
do
  FILENAME="$(basename "$f")"
  echo "Create package for ${FILENAME}"
  tar cfz "${DEST}/${FILENAME}.tar.gz" "./keys/${FILENAME}" "./ips/${FILENAME}"
  zip "${DEST}/${FILENAME}.zip" "./keys/${FILENAME}" "./ips/${FILENAME}"
done
