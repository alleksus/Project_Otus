#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')

spawn $(which mysql_secure_installation)

expect {
             "Enter password for user root:" { send -- "$MYSQL\r" }
             "New password:" { send -- "$Pass\r" }
             "Re-enter new password:" { send -- "$Pass\r" }
             "Change the password for root ? ((Press y|Y for Yes, any other key for No) :" { send -- "n\r" }
			 "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :" { send -- "y\r" }
             "Remove anonymous users? (Press y|Y for Yes, any other key for No) :" { send -- "y\r" }
			 "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :" { send -- "n\r" }
             "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :" { send -- "y\r" }
             "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :" { send -- "y\r" }
        }