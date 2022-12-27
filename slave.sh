#!binbash

User=root
Pass=Otus2022
DUMP="/tmp/$DB-export.sql"

# установка доп ПО
firewall-cmd --permanent --add-port=3306
systemctl restart firewalld
yum install -y yum-utils rpm wget tar nano mc git expect

#установка mysql

rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-5.noarch.rpm
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql80-community install mysql-community-server

systemctl enable --now mysqld

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

scp root@192.168.136.7:Project_Otus/config/slave_my.cnf /etc/my.cnf

systemctl restart mysqld

sleep 10s

mysql "-u$User" "-p$Pass" -e "CREATE USER root@'%' IDENTIFIED BY 'Otus2022';"
mysql "-u$User" "-p$Pass" -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' WITH GRANT OPTION;"

scp root@192.168.136.7:$DUMP $DUMP
