#!/bin/bash

User=root
Pass=Otus2022
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/backup/$TIMESTAMP"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
 
mkdir -p "$BACKUP_DIR/mysql"

stopslave=`$MYSQL "-u$User" root "-p$Pass" -e "STOP SLAVE;"`
databases=`$MYSQL "-u$User" "-p$Pass" -e "SHOW DATABASES;"`
 
for db in $databases; do
  $MYSQLDUMP --events --routines --databases $db --master-data=2 "-u$User" "-p$Pass" | gzip > "$BACKUP_DIR/mysql/$db.gz"
done

startslave=`$MYSQL "-u$User" "-p$Pass" -e "START SLAVE;"`