#!/bin/bash

User=root
Pass=Otus_2022

Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')

cat <<EOF | tee /tmp/binlog.txt
$Master_Status
EOF


