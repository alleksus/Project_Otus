#!binbash

User=root
Pass=Otus2022
MYSQL=/usr/bin/mysql
DUMP="/tmp/$DB-export.sql"
Master_Host=IP host
Slave_Host=IP Slave

# настройка firewall
firewall-cmd --permanent --add-service=http  
firewall-cmd --permanent --add-service=https 
firewall-cmd --permanent --add-port=8080/tcp --add-port=8081/tcp --add-port=8082/tcp --add-port=3306/tcp --add-port=9090/tcp --add-port=9100/tcp --add-port=9200/tcp --add-port=5601/tcp 

# установка доп ПО
setenforce 0
ssh root@$Slave_Host 'bash -s' < /путь/установка ПО slave.sh &
exit
yum install -y yum-utils rpm wget tar nano mc git expect openssh-server openssh-clients

# клонирование репозитория
git clone @ссылка на github@

#установка nginx
yum install -y epel-release 
yum install -y nginx 

#настройка

cp @папка git@/config/nginx.conf /etc/nginx/
cp @папка git@/config/default.conf /etc/nginx/conf.d/

systemctl enable --now nginx

#установка apache
yum install -y httpd

#настройка

cp -p @папка git@/config/httpd.conf /etc/httpd/conf.d/
cp -R @папка git@/config/www /var/www/

systemctl enable --now httpd

#установка mysql

rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql80-community install mysql-community-server

systemctl enable --now mysqld

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

cp @папка git@/config/my.cnf /etc/

systemctl restart mysqld

sleep 10

mysql "-u$User" "-p$Pass" -e "CREATE USER root@'%' IDENTIFIED BY 'Otus2022';"
mysql "-u$User" "-p$Pass" -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' WITH GRANT OPTION;"

mysql "-u$User" "-p$Pass" -e "CREATE DATABASE Otus;"

mysqldump "-u$User" "-p$Pass" --opt $DB > $DUMP
Master_Status=$(mysql "-u$User" "-p$Pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
Log_File=$(echo $Master_Status |cut -f1 -d ' ')
Log_Pos=$(echo $Master_Status |cut -f2 -d ' ')

scp $DUMP $Slave_Host:$DUMP >/dev/null 

ssh root@$Slave_Host
mysql "-u$User" "-p$Pass" -e "DROP DATABASE IF EXISTS $DB; CREAT DATABASE $DB;"
mysql "-u$User" "-p$Pass" $DB < $DUMP

mysql "-u$User" "-p$Pass" -e "STOP SLAVE; CHANGE MASTER TO MASTER_HOST='$Master_Host', MASTER_USER='$User', MASTER_PASSWORD='$Pass', MASTER_LOG_FILE='$Log_File', MASTER_LOG_POS='$Log_Pos'; START SLAVE;"
exit

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

cp prometheus-2.17.1.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.17.1.linux-amd64/promtool /usr/local/bin/

chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
chmod -R 700 /usr/local/bin/prometheus
chmod -R 700 /usr/local/bin/promtool

cp -r prometheus-2.17.1.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.17.1.linux-amd64/console_libraries /etc/prometheus
cp -r prometheus-2.17.1.linux-amd64/prometheus.yml /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /etc/prometheus/prometheus.yml

cp @папка git@/config/prometheus.service /etc/systemd/system/prometheus.service

wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

tar -zxvf node_exporter-0.18.1.linux-amd64.tar.gz
mv node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/node_exporter/
chmod -R 700 /usr/local/bin/node_exporter/

cp @папка git@/config/node_exporter.service /etc/systemd/system/node_exporter.service

systemctl enable --now prometheus
systemctl enable --now node_exporter

#установка elk

yum -y install java-openjdk-devel java-openjdk

cd @папка git@/rpms
rpm -i *.rpm

cp @папка git@/config/jvm.options /etc/elasticsearch/jvm.options.d/jvm.options
systemctl enable --now elasticsearch.service

cp @папка git@/config/kibana.yml /etc/kibana/kibana.yml
systemctl enable --now kibana

cp @папка git@/config/logstash.yml /etc/logstash/logstash.yml
cp @папка git@/config/logstash-nginx-es.conf /etc/logstash/conf.d/logstash-nginx-es.conf

systemctl restart logstash.service

cp @папка git@/config/filebeat.yml /etc/filebeat/filebeat.yml

systemctl enable --now filebeat
systemctl restart nginx






























