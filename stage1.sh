#!/bin/bash

User=root
Pass=Otus2022
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

#установка mysql на slave
#sshpass -p $Pass $User@$Slave_Host 'bash -s' < /Project_Otus/slave.sh
#exit

#установка nginx
yum install -y epel-release 
yum install -y nginx 

#настройка

\cp -u /root/Project_Otus/config/nginx.conf /etc/nginx/
\cp -u /root/Project_Otus/config/default.conf /etc/nginx/conf.d/

systemctl enable --now nginx

sleep 5

systemctl status nginx

#установка apache
yum install -y httpd

#настройка

\cp -u /root/Project_Otus/config/httpd.conf /etc/httpd/conf/
\cp -r /root/Project_Otus/config/www /var/www/

systemctl enable --now httpd

sleep 5

systemctl status httpd

#установка mysql

rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql80-community install mysql-community-server

systemctl enable --now mysqld

sleep 10

#настройка

root_temp_pass=$(grep "A temporary password" /var/log/mysqld.log)
echo "root_temp_pass: "$root_temp_pass
secure_mysql=$(expect -c "
set timeout 1
spawn mysql_secure_installation "-u$User" "-p#$root_temp_pass"
expect \"New password:\"
send \"$Pass\r\"
expect \"Re-enter new password:\"
send \"$Pass\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disable root login remotely?\"
send \"n\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Remove privilege tables now?\"
send \"y\r\"
expect eof
")

\cp -u /root/Project_Otus/config/my.cnf /etc/

systemctl restart mysqld

sleep 10

mysql "-u$User" "-p$Pass" -e "CREATE USER root@'%' IDENTIFIED BY 'Otus2022';"
mysql "-u$User" "-p$Pass" -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' WITH GRANT OPTION;"

mysql "-u$User" "-p$Pass" -e "CREATE DATABASE Otus;"

mysqldump "-u$User" "-p$Pass" --opt $DB > $DUMP
Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

sshpass -p $Pass $User@$Slave_Host
bash <(curl -Ls https://raw.githubusercontent.com/alleksus/Project_Otus/main/slave.sh)

mysql "-u$User" "-p$Pass" -e "DROP DATABASE IF EXISTS $DB; CREAT DATABASE $DB;"
mysql "-u$User" "-p$Pass" $DB < $DUMP

mysql "-u$User" "-p$Pass" -e "STOP SLAVE; CHANGE MASTER TO MASTER_HOST='$Master_Host', MASTER_USER='$User', MASTER_PASSWORD='$Pass', MASTER_LOG_FILE='$Log_File', MASTER_LOG_POS='$Log_Pos'; START SLAVE;"

#exit

systemctl restart mysqld

exit