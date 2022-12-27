#!/bin/bash

User=root
Pass=Otus_2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
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

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect "Enter password for user root:"
send "$MYSQL\r"
expect "New password:"
send "$Pass\r"
expect "Re-enter new password:"
send "$Pass\r"
expect "*:"
send "n\r"
expect "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "n\r"
expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect eof
")

echo "$SECURE_MYSQL"

\cp -u /root/Project_Otus/config/my.cnf /etc/
chmod -R 755 /var/lib/mysql/

systemctl restart mysqld

