#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

root_temp_pass=$(grep "A temporary password" /var/log/mysqld.log)

echo "root_temp_pass: "$root_temp_pass
secure_mysql=$(expect -c "
set timeout 1
spawn mysql_secure_installation "-u$User" "-p#$root_temp_pass"
expect \"New password:\"
send \"$Pass\"
expect \"Re-enter new password:\"
send \"$Pass\"
expect \"Change the root password?\"
send \"n\"
expect \"Remove anonymous users?\"
send \"y\"
expect \"Disable root login remotely?\"
send \"n\"
expect \"Remove test database and access to it?\"
send \"y\"
expect \"Remove privilege tables now?\"
send \"y\"
expect eof
")

echo "$SECURE_MYSQL"

\cp -u /root/Project_Otus/config/my.cnf /etc/

systemctl restart mysqld
