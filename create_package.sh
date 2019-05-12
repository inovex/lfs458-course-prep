#!/usr/bin/env bash
set +eu

export DEST="packages"

rm -rf packages/*.
mkdir -p packages

for f in ./ips/*;
do
  FILENAME="$(basename "$f")"
  echo "Create pacakge for ${FILENAME}"
  tar cfz "${DEST}/${FILENAME}.tar.gz" "keys/${FILENAME}" "ips/${FILENAME}"
done
