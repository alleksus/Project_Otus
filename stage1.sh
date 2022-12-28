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

sshpass -p Otus2022 ssh $User@$Slave_Host

# установка доп ПО
firewall-cmd --permanent --add-port=3306
systemctl restart firewalld
yum install -y yum-utils rpm wget tar nano mc git expect

#установка mysql slave server

rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql80-community install mysql-community-server

systemctl start mysqld
systemctl enable mysqld

sleep 10

systemctl status mysqld

#настройка

MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $13}')

mysql -uroot -p$MYSQL --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$Pass';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;"

scp root@192.168.136.7:/root/Project_Otus/config/slave_my.cnf /etc/my.cnf
chmod -R 755 /var/lib/mysql/

scp root@192.168.136.7:$DUMP $DUMP

mysql "-u$User" "-p$Pass" < $DUMP

mysql "-u$User" "-p$Pass" -e "STOP SLAVE; CHANGE MASTER TO MASTER_HOST='$Master_Host', MASTER_USER='repl', MASTER_PASSWORD='oTUSlave#2020', MASTER_LOG_FILE='$Log_File', MASTER_LOG_POS='$Log_Pos'; START SLAVE;"

systemctl restart mysqld




