#!/bin/bash

User=root
Pass=Otus_2022
DUMP="/tmp/$DB-export.sql"

# установка доп ПО
firewall-cmd --permanent --add-port=3306
systemctl restart firewalld
yum install -y yum-utils rpm wget tar nano mc git expect

#установка mysql

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
