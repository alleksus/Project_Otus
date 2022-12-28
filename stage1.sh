#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
DUMP="/tmp/mysql_dump.sql"
Master_Host=192.168.136.7
Slave_Host=192.168.136.8

# настройка firewall
firewall-cmd --permanent --add-service=http  
firewall-cmd --permanent --add-service=https 
firewall-cmd --permanent --add-port=8080/tcp --add-port=8081/tcp --add-port=8082/tcp --add-port=3306/tcp --add-port=9090/tcp --add-port=9100/tcp --add-port=9200/tcp --add-port=5601/tcp 
systemctl restart firewalld

# установка доп ПО
setenforce 0
yum install -y yum-utils rpm wget tar nano mc git expect sshpass

# клонирование репозитория
git clone git@github.com:alleksus/Project_Otus.git

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

\cp -u /root/Project_Otus/config/my.cnf /etc/
chmod -R 755 /var/lib/mysql/

systemctl restart mysqld
sleep 10

systemctl status mysqld

mysql "-u$User" "-p$Pass" -e "CREATE USER repl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'oTUSlave#2020';"
mysql "-u$User" "-p$Pass" -e "GRANT REPLICATION SLAVE ON *.* TO repl@'%';"
mysql "-u$User" "-p$Pass" -e "CREATE DATABASE Otus;"

databases=`$MYSQL "-u$User" "-p$Pass" -e "SHOW DATABASES;"`

for db in $databases; do
  $MYSQLDUMP --events --routines --databases $db --master-data=2 "-u$User" "-p$Pass" > $DUMP
done

Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')




