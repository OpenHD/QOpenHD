#!/bin/bash
# Deployment tarballs must never apply the build user's ownership to / or /usr.
set -euo pipefail
deploy=$(realpath "${1:?Usage: nxp-pack-deploy.sh DEPLOY_DIR OUTPUT_ARCHIVE}")
archive=$(realpath -m "${2:?Usage: nxp-pack-deploy.sh DEPLOY_DIR OUTPUT_ARCHIVE}")
test -d "$deploy"
tar --numeric-owner --owner=0 --group=0 -czf "$archive" -C "$deploy" .
