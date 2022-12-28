#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
DUMP="/tmp/mysql_dump.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

databases=$(mysql "-u$User" "-p$Pass" -e "SHOW DATABASES;")

for db in $databases; do
  $MYSQLDUMP --events --routines --databases $db --master-data=2 "-u$User" "-p$Pass" > $DUMP
done

Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')




