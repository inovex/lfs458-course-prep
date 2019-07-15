#!/usr/bin/env bash
set +xeu

export DEST="./packages"

rm -rf "${DEST}/*"
mkdir -p "${DEST}"

for f in ${@};
do
  FILENAME="$(basename "$f")"
  echo "Create pacakge for ${FILENAME}"
  tar cfz "${DEST}/${FILENAME}.tar.gz" "./keys/${FILENAME}" "./ips/${FILENAME}"
done
