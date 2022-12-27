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