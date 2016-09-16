#!/bin/bash
# The MIT License (MIT)

# Copyright (c) 2016 Cory Gillenkirk

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Supported Versions: Ubuntu, Debian and CentOS 6.x

# Update Resolve Servers
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# File Check
if [ -f /etc/network/interfaces ]; then
sed -i 's/dns-nameservers \(.*\)/\Edns-nameservers 8.8.8.8 8.8.4.4/g' /etc/network/interfaces
fi

# Update
aptitude -y update
yum -y update

# Install: lsb-release
aptitude -y install lsb-release sudo curl
yum -y install redhat-lsb curl

# Get Public IP
IP="$(curl -4 icanhazip.com)"

# Password Generator
# MySQL, Multicraft Daemon, Multicraft Panel, Multicraft Admin, phpMyAdmin BlowFish Secret
export MySQLRoot=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Daemon=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Panel=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export AdminPassword=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export BlowFish=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`

# Detecting Distrubution of Linux
# Ubuntu, Debian and CentOS
DISTRO="$(lsb_release -si)"
VERSION="$(lsb_release -sr | cut -d. -f1)"
OS="$DISTRO$VERSION"

# Begin Ubuntu
if [ "${DISTRO}" = "Ubuntu" ] || [ "${DISTRO}" = "Debian" ] ; then
apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
echo "deb http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee /etc/apt/sources.list.d/percona.list
echo "deb-src http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee -a /etc/apt/sources.list.d/percona.list
apt-get -y update
export DEBIAN_FRONTEND="noninteractive"
apt-get -y install apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip percona-server-server-5.6 curl git
# Begin CentOS
elif [ "${OS}" = "CentOS6" ] ; then
yum -y install https://mirror.webtatic.com/yum/el6/latest.rpm
yum -y install http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
yum -y remove *mysql* php-*
mv /var/lib/mysql /var/lib/mysql-old
yum -y update
yum -y install wget nano zip unzip httpd Percona-Server-client-56.x86_64 Percona-Server-devel-56.x86_64 Percona-Server-server-56.x86_64 Percona-Server-shared-56.x86_64 php56w php56w-pdo php56w-mysql php56w-mbstring sqlite php56w-gd freetype curl mlocate git
/sbin/chkconfig --level 2345 httpd on;
elif [ "${OS}" = "CentOS7" ] ; then
#yum -y install https://mirror.webtatic.com/yum/el6/latest.rpm
yum -y install http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
yum -y remove *mysql* php-*
mv /var/lib/mysql /var/lib/mysql-old
yum -y update
#yum -y install wget nano zip unzip httpd Percona-Server-client-56.x86_64 Percona-Server-devel-56.x86_64 Percona-Server-server-56.x86_64 Percona-Server-shared-56.x86_64 php56w php56w-pdo php56w-mysql php56w-mbstring sqlite php56w-gd freetype curl mlocate git
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

WebRoot="/var/www/html"

# Multicraft Download
mkdir /home/root/
cd /home/root/
wget --no-check-certificate http://multicraft.org/download/linux64 -O multicraft.tar.gz
tar -xf multicraft.tar.gz
rm -fv multicraft.tar.gz
cd multicraft
rm -rf jar api setup.sh eula.txt readme.txt
mv panel multicraft
mv multicraft.conf.dist multicraft.conf
mv multicraft ${WebRoot}/
mkdir jar
cd jar
wget --no-check-certificate "https://github.com/JustOneMoreBlock/shell-scripts/blob/master/files/multicraft-jar-confs.zip?raw=true" -O multicraft-jar-confs.zip;
unzip -o multicraft-jar-confs.zip
rm -fv multicraft-jar-confs.zip
wget http://s3.amazonaws.com/MCProHosting-Misc/Spigot/Spigot.jar -O Spigot.jar
wget http://s3.amazonaws.com/MCProHosting-Misc/PaperSpigot/PaperSpigot.jar -O PaperSpigot.jar
wget http://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar -O Bungeecord.jar
cd /home/root/multicraft/

# Multicraft Panel
ProtectedConf="/protected/config/config.php"
cd ${WebRoot}/multicraft/
mv protected /
mv ${ProtectedConf}.dist ${ProtectedConf}
chmod 777 assets
chmod 777 /protected/runtime/
chmod 777 ${ProtectedConf}
sed -i 's/dirname(__FILE__)./\E/g' index.php
sed -i 's/dirname(__FILE__)./\E/g' install.php
rm -fv api.php
# rm -fv api.php install.php

# Automated phpMyAdmin Installer
cd ${WebRoot}/
git clone --depth=1 --branch=STABLE git://github.com/phpmyadmin/phpmyadmin.git phpMyAdmin
mv ${WebRoot}/phpMyAdmin/config.sample.inc.php ${WebRoot}/phpMyAdmin/config.inc.php
sed -i "s/\$cfg\[.blowfish_secret.\]\s*=.*/\$cfg['blowfish_secret'] = '${BlowFish}';/" ${WebRoot}/phpMyAdmin/config.inc.php

# php.ini Auto-Detector
PHP="$(php -r "echo php_ini_loaded_file();")"
rm -fv /etc/php.ini
ln -s ${PHP} /etc/php.ini

# Modify php.ini Settings
sed -i 's/upload_max_filesize = \(.*\)/\Eupload_max_filesize = 100M/g' /etc/php.ini
sed -i 's/post_max_size = \(.*\)/\Epost_max_size = 100M/g' /etc/php.ini
sed -i 's/max_execution_time = \(.*\)/\Emax_execution_time = 300/g' /etc/php.ini
sed -i 's/max_input_time = \(.*\)/\Emax_input_time = 600/g' /etc/php.ini

cat /root/mc.conf

# Memory Checker
MemTotal="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
Memory="$((${MemTotal} / 1024))"

# Multicraft Config
MulticraftConf="/home/root/multicraft/multicraft.conf"
sed -i 's/user =\(.*\)/\Euser = root/g' ${MulticraftConf}
sed -i 's/webUser =\(.*\)/\EwebUser = /g' ${MulticraftConf}
sed -i 's/\#id =\(.*\)/\Eid = 1/g' ${MulticraftConf}
sed -i 's/\#database = mysql\(.*\)/\Edatabase = mysql:host=127.0.0.1;dbname=daemon/g' ${MulticraftConf}
sed -i 's/\#dbUser =\(.*\)/\EdbUser = daemon/g' ${MulticraftConf}
sed -i "s/\#dbPassword =\(.*\)/\EdbPassword = ${Daemon}/g" ${MulticraftConf}
sed -i 's/\#name =\(.*\)/\Ename = Server 1/g' ${MulticraftConf}
sed -i "s/#totalMemory =\(.*\)/\EtotalMemory = ${Memory}/g" ${MulticraftConf}
sed -i "s/\(.*\)baseDir =\(.*\)/\EbaseDir = \/home\/root\/multicraft\//g" ${MulticraftConf}
sed -i 's/\#multiuser =\(.*\)/\Emultiuser = true/g' ${MulticraftConf}
sed -i "s/\(.*\)forbiddenFiles\(.*\)/\#forbiddenFiles = /g" ${MulticraftConf}
sed -i "s/\ip = 127.0.0.1/\Eip = ${IP}/g" ${MulticraftConf}

# Multicraft Panel Config
# Screw sed on this one. :)
cd /protected/config/
cat > config.php << eof
<?php
return array (
  'panel_db' => 'mysql:host=localhost;dbname=panel',
  'daemon_db' => 'mysql:host=localhost;dbname=daemon',
  'daemon_password' => 'none',
  'superuser' => 'admin',
  'api_enabled' => false,
  'api_allow_get' => false,
  'user_api_keys' => false,
  'admin_name' => 'Multicraft Administrator',
  'admin_email' => '',
  'show_serverlist' => 'user',
  'hide_userlist' => true,
  'ftp_client_disabled' => false,
  'ftp_client_passive' => false,
  'templates_disabled' => false,
  'ajax_updates_disabled' => false,
  'ajax_update_interval' => '2000',
  'timeout' => '5',
  'mark_daemon_offline' => '10',
  'theme' => '',
  'mobile_theme' => '',
  'user_theme' => false,
  'language' => '',
  'login_tries' => '4',
  'login_interval' => '300',
  'ajax_serverlist' => false,
  'status_banner' => true,
  'mail_welcome' => false,
  'mail_assign' => false,
  'sqlitecache_schema' => false,
  'sqlitecache_commands' => false,
  'user_mysql' => true,
  'user_mysql_host' => 'localhost',
  'user_mysql_user' => 'root',
  'user_mysql_pass' => '${MySQLRoot}',
  'user_mysql_prefix' => 'db_',
  'user_mysql_admin' => 'http://${IP}/phpMyAdmin/index.php',
  'show_repairtool' => 'none',
  'register_disabled' => true,
  'reset_token_hours' => '0',
  'default_ignore_ip' => false,
  'default_display_ip' => '',
  'show_memory' => true,
  'log_bottomup' => true,
  'admin_ips' => '',
  'api_ips' => '',
  'enable_csrf_validation' => true,
  'enable_cookie_validation' => true,
  'use_bukget' => false,
  'auto_jar_submit' => 'yes',
  'pw_crypt' => 'sha512_crypt',
  'ip_auth' => true,
  'cpu_display' => 'core',
  'ram_display' => '',
  'enable_disk_quota' => false,
  'block_chat_characters' => true,
  'log_console_commands' => false,
  'show_delete_all_players' => 'superuser',
  'kill_button' => 'none',
  'fill_port_gaps' => true,
  'support_legacy_daemons' => false,
  'panel_db_user' => 'panel',
  'panel_db_pass' => '${Panel}',
  'daemon_db_user' => 'daemon',
  'daemon_db_pass' => '${Daemon}',
  'min_pw_length' => '',
  'default_displayed_ip' => '',
  'support_legacy_api' => false,
);
eof

# Auto Java Installer
if [ "${DISTRO}" = "Ubuntu" ] ; then
sudo apt-get -y install software-properties-common python-software-properties debconf-utils
sudo apt-get -y update
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get -y update
sudo echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
sudo echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
sudo apt-get -y install oracle-java8-installer
elif [ "${DISTRO}" = "Debian" ] ; then
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | sudo tee /etc/apt/sources.list.d/java-8-debian.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
sudo apt-get -y update
sudo apt-get -y install debconf-utils
sudo apt-get -y update
sudo echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
sudo echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
sudo apt-get -y install oracle-java8-installer
elif [ "${DISTRO}" = "CentOS" ] ; then
# Author: Mike G. aka metalcated and partially forked from n0ts (https://github.com/metalcated/)
# Why copy and paste snipplets? It's a good script and I'll just store in my repo. :)
wget https://raw.githubusercontent.com/JustOneMoreBlock/shell-scripts/master/install_java.sh -O install_java.sh
chmod +x install_java.sh
sh install_java.sh jre8 rpm
rm -fv install_java.sh
fi

java -version

# TESTED: Everything above should work on all supported distros.

# UNTESTED
DaemonQuery="$(mysql -p${Daemon} -u daemon -D daemon)"
PanelQuery="$(mysql -p${Panel} -u panel -D panel)"

# Automatically Import MySQL Database Schema's, thus removing the web installer. :)
${DaemonQuery} < /protected/data/daemon/schema.mysql.sql
${PanelQuery} < /protected/data/panel/schema.mysql.sql

# Configure New Admin Password
# Using: ${AdminPassword} and set in password.
# SaltPassword=$(`${AdminPassword}`)
# Need to read to figure out a solution for this.
# ERROR 1054 (42S22) at line 1: Unknown column 'admin' in 'where clause'
${PanelQuery} -e "UPDATE user SET password="${SaltPassword}" WHERE name="admin";"
echo "Updating: Admin Password ..."

# Daemon MySQL Changes
${DaemonQuery} -e "INSERT INTO setting (key, value) VALUES ('defaultServerIp', '1');"
echo "Set: Use Daemon IP ..."
${DaemonQuery} -e "INSERT INTO setting (key, value) VALUES ('minecraftEula', 'auto');"
echo "Set: Auto Enable EULA ..."

# Enable Auto Start on Reboot
echo "/home/root/multicraft/bin/multicraft start" > /etc/rc.local

# Restart Services
service apache2 stop
service apache2 start
/sbin/service httpd stop
/sbin/service httpd start

# Check System

# Output Vars
cd /root/
cat > login.conf << eof
# Control Panel Link:
http://${IP}/multicraft/index.php
Username: admin
Password: ${AdminPassword}

# phpMyAdmin Link
http://${IP}/phpMyAdmin/index.php
Username: root
Password: ${MySQLRoot}
eof

cat /root/login.conf