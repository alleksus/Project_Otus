#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/mysql_dump.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

mysql "-u$User" "-p$Pass" -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' WITH GRANT OPTION;"
mysql "-u$User" "-p$Pass" -e "CREATE DATABASE Otus;"

mysql "-u$User" root "-p$Pass" -e "STOP SLAVE;"
mysqldump "-u$User" "-p$Pass" --events --routines --all-databases --master-data=2 > $DUMP


Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

mysql "-u$User" root "-p$Pass" -e "START SLAVE;"




