#!/usr/bin/env bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')

SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect "Enter password for user root:"
send "$MYSQL\r"

expect "Change the password for root ? ((Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "New password:"
send "$Pass\r"

expect "Re-enter new password:"
send "$Pass\r"

expect "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect eof
")

echo "$SECURE_MYSQL"