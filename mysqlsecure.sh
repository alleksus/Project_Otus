#!/usr/bin/expect

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')

expect {
             "Enter password for user root:" { send "$MYSQL\r"; exp_continue }
             "New password:" { send "$Pass\r"; exp_continue }
             "Re-enter new password:" { send "$Pass\r"; exp_continue }
             "Change the password for root ? ((Press y|Y for Yes, any other key for No) :" { send "n\r"; exp_continue }
			 "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :" { send "y\r"; exp_continue }
             "Remove anonymous users? (Press y|Y for Yes, any other key for No) :" { send "y\r"; exp_continue }
			 "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :" { send "n\r"; exp_continue }
             "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :" { send "y\r"; exp_continue }
             "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :" { send "y\r"; exp_continue }
        }