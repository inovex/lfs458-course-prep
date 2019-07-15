#!/usr/bin/env bash
set -eu

export DEST="./packages"

rm -rf "${DEST}/*"
mkdir -p "${DEST}"

for f in ${@};
do
  FILENAME="$(basename "$f")"
  echo "Create package for ${FILENAME}"
  tar cfz "${DEST}/${FILENAME}.tar.gz" "./keys/${FILENAME}" "./ips/${FILENAME}"
done
