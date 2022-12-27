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
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$Pass\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

scp root@192.168.136.7:Project_Otus/config/slave_my.cnf /etc/my.cnf

systemctl restart mysqld

sleep 10

mysql "-u$User" "-p$Pass" -e "CREATE USER root@'%' IDENTIFIED BY 'Otus2022';"
mysql "-u$User" "-p$Pass" -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' WITH GRANT OPTION;"

scp root@192.168.136.7:$DUMP $DUMP
