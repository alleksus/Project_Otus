#!/bin/bash

User=root
Pass=Otus_2022
MYSQLDUMP=/usr/bin/mysqldump
DUMP="/tmp/mysql_dump.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

sshpass -p Otus2022 $User@$Slave_Host





