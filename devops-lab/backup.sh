#!/bin/bash
source $(dirname $0)/lib.sh
usage() { echo "Usage: $0 -s <source> -d <dest> [-c] [-h]"; exit 1; }
COMPRESS=false
while getopts 's:d:ch' opt; do
  case $opt in
    s) SOURCE=$OPTARG ;;
    d) DEST=$OPTARG ;;
    c) COMPRESS=true ;;
    h) usage ;;
    *) usage ;;
  esac
done
if [ -z "$SOURCE" ] || [ -z "$DEST" ]; then usage; fi
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="backup-${TIMESTAMP}"
$COMPRESS && tar czf ${DEST}/${BACKUP_NAME}.tar.gz $SOURCE && log_info "Compressed backup: ${BACKUP_NAME}.tar.gz" || cp -r $SOURCE ${DEST}/${BACKUP_NAME} && log_info "Plain backup: ${BACKUP_NAME}"
