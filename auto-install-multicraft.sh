# Update Resolve Servers
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# File Check
if [ -f /etc/network/interfaces ]; then
sed -i 's/dns-nameservers \(.*\)/\Edns-nameservers 8.8.8.8 8.8.4.4/g' /etc/network/interfaces
sudo /etc/init.d/resolvconf restart
fi

# Get Public IP
# dig not found on debian
IP="$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')"

# Update
aptitude -y update
yum -y update

# Install: lsb-release
aptitude -y install lsb-release sudo
yum -y install redhat-lsb

# Password Generator
# MySQL, Multicraft Daemon, Multicraft Panel, Multicraft Admin, phpMyAdmin BlowFish Secret
export MySQLRoot=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Daemon=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Panel=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export AdminPassword=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export BlowFish=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`

# Detecting Distrubution of Linux
# Ubuntu, Debian and CentOS
OS="$(lsb_release -si)"

# Begin Ubuntu
if [ "${OS}" = "Ubuntu" ] || [ "${OS}" = "Debian" ] ; then
apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
echo "deb http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee /etc/apt/sources.list.d/percona.list
echo "deb-src http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee -a /etc/apt/sources.list.d/percona.list
apt-get -y update
export DEBIAN_FRONTEND="noninteractive"
apt-get -y install apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip percona-server-server-5.6
# Begin CentOS
elif [ "${OS}" = "CentOS" ] ; then
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
rpm -Uvh http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
yum -y remove *mysql* php-*
mv /var/lib/mysql /var/lib/mysql-old
yum -y update
yum -y install wget nano zip unzip httpd Percona-Server-client-56.x86_64 Percona-Server-devel-56.x86_64 Percona-Server-server-56.x86_64 Percona-Server-shared-56.x86_64 php56w php56w-pdo php56w-mysql php56w-mbstring sqlite php56w-gd freetype
/sbin/chkconfig --level 2345 httpd on;
fi

# Set MySQL Password
/sbin/service mysql start
service mysql start
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MySQLRoot}');"

# Save Generated MySQL Root Password.
cd /root/
cat > .my.cnf << eof
[client]
user="root"
pass="${MySQLRoot}"
eof

# Multicraft Databases
mysql -e "CREATE DATABASE daemon;"
mysql -e "CREATE DATABASE panel;"
mysql -e "GRANT ALL ON daemon.* to daemon@localhost IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@localhost IDENTIFIED BY '${Panel}';"
mysql -e "GRANT ALL ON daemon.* to daemon@'%' IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@'%' IDENTIFIED BY '${Panel}';"

cd /root/
cat > mc.conf << eof
MySQLRoot="${MySQLRoot}"
Daemon="${Daemon}"
Panel="${Panel}"
eof

# Multicraft Download
mkdir /home/root/
cd /home/root/
wget --no-check-certificate http://multicraft.org/download/linux64 -O multicraft.tar.gz
tar -xf multicraft.tar.gz
cd multicraft
rm -rf jar api setup.sh eula.txt readme.txt
mv panel multicraft
mv multicraft.conf.dist multicraft.conf
mv multicraft /var/www/html/
mkdir jar
cd jar
wget --no-check-certificate "https://github.com/JustOneMoreBlock/shell-scripts/blob/master/files/multicraft-jar-confs.zip?raw=true" -O multicraft-jar-confs.zip;
unzip -o multicraft-jar-confs.zip
rm -fv multicraft-jar-confs.zip
cd /home/root/multicraft/

# TEST PASSED: Ubuntu

# Multicraft Panel
ProtectedConf="/protected/config/config.php"
cd /var/www/html/multicraft/
mv protected /
mv ${ProtectedConf}.dist ${ProtectedConf}
chmod 777 assets
chmod 777 /protected/runtime/
chmod 777 ${ProtectedConf}
sed -i 's/dirname(__FILE__)./\E/g' index.php
sed -i 's/dirname(__FILE__)./\E/g' install.php
rm -fv api.php
# rm -fv api.php install.php

# phpMyAdmin
# Let's add phpMyAdmin Support!
# Find a way to get latest version.
phpMyAdminFile="https://files.phpmyadmin.net/phpMyAdmin/4.6.3/phpMyAdmin-4.6.3-all-languages.zip"
cd /var/www/html/
wget --no-check-certificate ${phpMyAdminFile} -O phpMyAdmin.zip
unzip -o phpMyAdmin.zip
rm -fv phpMyAdmin.zip
mv phpMyAdmin-* phpMyAdmin
mv /var/www/html/phpMyAdmin/config.sample.inc.php /var/www/html/phpMyAdmin/config.inc.php
sed -i "s/\$cfg\[.blowfish_secret.\]\s*=.*/\$cfg['blowfish_secret'] = '${BlowFish}';/" /var/www/html/phpMyAdmin/config.inc.php

# Differnt ini file on Ubuntu?
# /etc/php5/cli/php.ini
ln -s /etc/php5/cli/php.ini /etc/php.ini

# Modify php.ini Settings
sed -i 's/upload_max_filesize = \(.*\)/\Eupload_max_filesize = 100M/g' /etc/php.ini
sed -i 's/post_max_size = \(.*\)/\Epost_max_size = 100M/g' /etc/php.ini
sed -i 's/max_execution_time = \(.*\)/\Emax_execution_time = 300/g' /etc/php.ini
sed -i 's/max_input_time = \(.*\)/\Emax_input_time = 600/g' /etc/php.ini

cat /root/mc.conf

# Multicraft Config
# LOTS of sed magic here!
# Add memory checker
kB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
Memory="${GetMemory} / 1024"

MulticraftConf="/home/root/multicraft/multicraft.conf"
sed -i 's/user =\(.*\)/\Euser = root/g' ${MulticraftConf}
sed -i 's/\#id =\(.*\)/\Eid = 1/g' ${MulticraftConf}
sed -i 's/\#database = mysql\(.*\)/\Edatabase = mysql:host=127.0.0.1;dbname=daemon/g' ${MulticraftConf}
sed -i 's/\#dbUser =\(.*\)/\EdbUser = daemon/g' ${MulticraftConf}
# sed -i "s/\#dbPassword =\(.*\)/\EdbPassword = ${Daemon}/g" ${MulticraftConf}
sed -i 's/\#name =\(.*\)/\Ename = Server 1/g' ${MulticraftConf}
# sed -i "s/totalMemory =\(.*\)/\EtotalMemory = ${Memory}/g" ${MulticraftConf}
# sed -i "s/\baseDir =\(.*\)/\EbaseDir = \/home\/root\/multicraft\/g" ${MulticraftConf}
sed -i 's/\#multiuser =\(.*\)/\Emultiuser = true/g' ${MulticraftConf}
# sed -i 's/\forbiddenFiles =\(.*\)/\E#forbiddenFiles =/g' ${MulticraftConf}
sed -i "s/\ip = 127.0.0.1/\Eip = ${IP}/g" ${MulticraftConf}

# We should add-in an auto install for Java 8. :)
# Ubuntu
# Apparently it doesn't work on Debian. :(
# Same thing but different
# http://tecadmin.net/install-java-8-on-debian/
sudo apt-get -y install software-properties-common python-software-properties
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get -y update
# This has a EULA to accept. Need to automatically say, Yes.
sudo apt-get -y install oracle-java8-installer
java -version
# CentOS
# Need JRE

# Permissions and Last Minute Settings
# Debian has
# www-data:x:33:33:www-data:/var/www/html:/bin/sh
if [ "${OS}" = "Ubuntu" ] ; then
sed -i 's/webUser =\(.*\)/\EwebUser = www-data:www-data/g' ${MulticraftConf}
chown -R www-data:www-data /protected/
chown -R www-data:www-data /var/www/html/multicraft/
elif [ "${OS}" = "Debian" ] ; then
# Debian has
# www-data:x:33:33:www-data:/var/www:/bin/sh
# Could update apache file.
sed -i 's/webUser =\(.*\)/\EwebUser = www-data:www-data/g' ${MulticraftConf}
chown -R www-data:www-data /protected/
chown -R www-data:www-data /var/www/html/multicraft/
elif [ "${OS}" = "CentOS" ] ; then
sed -i 's/webUser =\(.*\)/\EwebUser = /g' ${MulticraftConf}
chown -R nobody:nobody /protected/
chown -R nobody:nobody /var/www/html/multicraft/
fi

# Debian has a different webRoot?

# Multicraft Panel Config
# LOTS of sed magic here!
# Too tired to do this.
# 'panel_db' => 'mysql:host=localhost;dbname=multicraft_panel',
# 'panel_db_user' => 'root',
# 'panel_db_pass' => '',

# 'daemon_db' => 'mysql:host=localhost;dbname=multicraft_daemon',
# 'daemon_db_user' => 'root',
# 'daemon_db_pass' => 'testing',

#// Allow Users to Create a MySQL Database
# 'user_mysql' => false,
# // User MySQL DB information
# 'user_mysql_host' => '',
# 'user_mysql_user' => '',
# 'user_mysql_pass' => '',
# 'user_mysql_prefix' => '',
# 'user_mysql_admin' => '',

# First Attempt and UNTESTED! I'll leave that commented above, just incase.
sed -i "s/ 'panel_db' => 'mysql:host=localhost;dbname=multicraft_panel',/\E 'panel_db' => 'mysql:host=localhost;dbname=panel',/g" ${ProtectedConf}
sed -i "s/ 'panel_db_user' => 'root',/\E 'panel_db_user' => 'panel',/g" ${ProtectedConf}
sed -i "s/ 'panel_db_pass' => '',/\E 'panel_db_pass' => '${Panel}',/g" ${ProtectedConf}
sed -i "s/ 'daemon_db' => 'mysql:host=localhost;dbname=multicraft_daemon',/\E 'daemon_db' => 'mysql:host=localhost;dbname=daemon',/g" ${ProtectedConf}
sed -i "s/ 'daemon_db_user' => 'root',/\E 'daemon_db_user' => 'daemon',/g" ${ProtectedConf}
sed -i "s/ 'daemon_db_pass' => 'testing',/\E 'daemon_db_pass' => '${Daemon}',/g" ${ProtectedConf}
sed -i "s/ 'user_mysql' => false,/\E'user_mysql' => true,/g" ${ProtectedConf}
sed -i "s/ 'user_mysql_host' => '',/\E 'user_mysql_host' => 'localhost',/g" ${ProtectedConf}
sed -i "s/ 'user_mysql_user' => '',/\E 'user_mysql_user' => 'root',/g" ${ProtectedConf}
sed -i "s/ 'user_mysql_pass' => '',/\E 'user_mysql_pass' => '${MySQLRoot}',/g" ${ProtectedConf}
sed -i "s/ 'user_mysql_prefix' => '',/\E 'user_mysql_prefix' => 'db_',/g" ${ProtectedConf}
sed -i "s/ 'user_mysql_admin' => '',/\E 'user_mysql_admin' => '${IP}/phpMyAdmin/index.php',/g" ${ProtectedConf}

# Automatically Import MySQL Database Schema's, thus removing the web installer. :)
mysql -p${Daemon} -u daemon daemon < /protected/data/daemon/schema.mysql.sql
mysql -p${Panel} -u panel panel < /protected/data/panel/schema.mysql.sql

# Configure New Admin Password
# Using: ${AdminPassword} and set in password.
# SaltPassword=$(`${AdminPassword}`)
# Need to read to figure out a solution for this.
# ERROR 1054 (42S22) at line 1: Unknown column 'admin' in 'where clause'
mysql -p${panel} -u panel -D panel -e "UPDATE user SET password="${SaltPassword}" WHERE name="admin";"
echo "Updating: Admin Password ..."

# Daemon MySQL Changes
mysql -p${Daemon} -u daemon daemon -e "INSERT INTO setting VALUES('defaultServerIp', '1');"
echo "Set: Use Daemon IP ..."
mysql -p${Daemon} -u daemon daemon -e "INSERT INTO setting VALUES('minecraftEula', 'auto');"
echo "Set: Auto Enable EULA ..."

# Enable Auto Start on Reboot
echo "/home/root/multicraft/bin/multicraft start" >> /etc/rc.local

# Restart Services
service apache2 stop
service apache2 start
/sbin/service httpd stop
/sbin/service httpd start

# Check System

# Output Vars
echo ""
echo "# Control Panel Link:"
echo "http://${IP}/multicraft/index.php"
echo "Username: admin"
echo "Password: ${AdminPassword}"
echo ""
echo "# phpMyAdmin Link"
echo "http://${IP}/phpMyAdmin/index.php"
echo "Username: root"
echo "Password: ${MySQLRoot}"
echo ""