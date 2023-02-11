#!binbash

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

# установка nginx
yum install -y epel-release 
yum install -y nginx 

# настройка

\cp -u /root/Project_Otus/config/nginx.conf /etc/nginx/
\cp -u /root/Project_Otus/config/default.conf /etc/nginx/conf.d/

systemctl enable --now nginx

sleep 3s

systemctl status nginx

# установка apache
yum install -y httpd

# настройка

\cp -u /root/Project_Otus/config/httpd.conf /etc/httpd/conf/
\cp -r /root/Project_Otus/config/www /var/www/

systemctl enable --now httpd

sleep 3s

systemctl status httpd

#установка mysql

rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql80-community install mysql-community-server

systemctl enable --now mysqld

sleep 10

#настройка

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

databases=$(mysql "-u$User" "-p$Pass" -e "SHOW DATABASES;")

for db in $databases; do
  $MYSQLDUMP --events --routines --databases $db --master-data=2 "-u$User" "-p$Pass" > $DUMP
done

Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

cat <<EOF | sudo tee /tmp/binlog.txt
$Log_File
$Log_Pos
EOF

sshpass -p $Pass $User@$Slave_Host
bash <(curl -Ls https://raw.githubusercontent.com/alleksus/Project_Otus/main/slave.sh)

sleep 60

systemctl restart mysqld

#установка prometheus и node_exporter

timedatectl set-timezone Europe/Moscow

wget https://github.com/prometheus/prometheus/releases/download/v2.17.1/prometheus-2.17.1.linux-amd64.tar.gz

mkdir /var/lib/prometheus
mkdir /etc/prometheus

groupadd prometheus
useradd -g prometheus -s /sbin/nologin prometheus

chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

tar -zxvf prometheus-2.17.1.linux-amd64.tar.gz

\cp -u prometheus-2.17.1.linux-amd64/prometheus /usr/local/bin/
\cp -u prometheus-2.17.1.linux-amd64/promtool /usr/local/bin/

chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
chmod -R 700 /usr/local/bin/prometheus
chmod -R 700 /usr/local/bin/promtool

\cp -u prometheus-2.17.1.linux-amd64/consoles /etc/prometheus
\cp -u prometheus-2.17.1.linux-amd64/console_libraries /etc/prometheus
\cp -u prometheus-2.17.1.linux-amd64/prometheus.yml /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /etc/prometheus/prometheus.yml

\cp -u /root/Project_Otus/config/prometheus.service /etc/systemd/system/

wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

tar -zxvf node_exporter-0.18.1.linux-amd64.tar.gz
mv node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/node_exporter/
chmod -R 700 /usr/local/bin/node_exporter/

\cp -u /root/Project_Otus/config/node_exporter.service /etc/systemd/system/

systemctl enable --now prometheus

sleep 3
 
systemctl enable --now node_exporter

sleep 3

#установка elk

yum install -y java-openjdk-devel java-openjdk

cd /root/rpms
rpm -i *.rpm

\cp -u /root/Project_Otus/config/jvm.options /etc/elasticsearch/jvm.options.d/
systemctl enable --now elasticsearch.service

sleep 10

\cp -u /root/Project_Otus/config/kibana.yml /etc/kibana/
systemctl enable --now kibana

sleep 3

\cp -u /root/Project_Otus/config/logstash.yml /etc/logstash/
\cp -u /root/Project_Otus/config/logstash-nginx-es.conf /etc/logstash/conf.d/

systemctl restart logstash.service

sleep 3

\cp -u /root/Project_Otus/config/filebeat.yml /etc/filebeat/

systemctl enable --now filebeat

sleep 3

systemctl restart nginx