#!/bin/bash

User=root
Pass=Otus_2022
DUMP="/tmp/mysql_dump.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

scp root@192.168.136.7:/tmp/binlog.txt /tmp/binlog.txt
scp root@192.168.136.7:/root/Project_Otus/config/slave_my.cnf /etc/my.cnf
scp root@192.168.136.7:$DUMP $DUMP

mysql "-u$User" "-p$Pass" < $DUMP

Master_Status=$(cat /tmp/binlog.txt)
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

mysql "-u$User" "-p$Pass" -e "STOP SLAVE;" 
mysql "-u$User" "-p$Pass" -e "CHANGE MASTER TO MASTER_HOST='$Master_Host', MASTER_USER='repl', MASTER_PASSWORD='oTUSlave#2020', MASTER_LOG_FILE='$Log_File', MASTER_LOG_POS=$Log_Pos, GET_MASTER_PUBLIC_KEY = 1;" 
mysql "-u$User" "-p$Pass" -e "START SLAVE;"

systemctl restart mysqld
