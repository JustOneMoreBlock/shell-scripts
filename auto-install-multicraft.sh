#!/bin/bash
# The MIT License (MIT)

# Copyright (c) 2016-2018 Cory Gillenkirk

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

# Supported Versions: Ubuntu, Debian and CentOS.

# Supported Versions (TESTED):
# - Ubuntu 14.04.05 x64
# - Ubuntu 16.04.04 x64
# - Ubuntu 18.04 x64

# - Debian 8.10 x64
# - Debian 9.5 x64

# - CentOS 6.9 x64
# - CentOS 7.5 x64

# Update Resolve Servers
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# File Check
if [ -f /etc/network/interfaces ]; then
sed -i 's/dns-nameservers \(.*\)/\Edns-nameservers 8.8.8.8 8.8.4.4/g' /etc/network/interfaces
fi

# Install: lsb-release
EXTRA="sudo curl ntpdate ca-certificates git python dos2unix"
apt-get -y install lsb-release ${EXTRA}
yum -y install redhat-lsb ${EXTRA}
/usr/sbin/ntpdate -u pool.ntp.org

# Get Public Interface
IFACE="$(/sbin/route | grep '^default' | grep -o '[^ ]*$')"

# Password Generator
# MySQL, Multicraft Daemon, Multicraft Panel, Multicraft Admin, phpMyAdmin BlowFish Secret
PasswordGenerator () {
cat /dev/urandom | tr -dc "A-Za-z0-9" | dd bs=$1 count=1 2>/dev/null;
}

export MySQLRoot=`PasswordGenerator 25`
export Daemon=`PasswordGenerator 25`
export Panel=`PasswordGenerator 25`
export DaemonPassword=`PasswordGenerator 25`
export AdminPassword=`PasswordGenerator 25`
export BlowFish=`PasswordGenerator 32`

# Detecting Distrubution of Linux
# Ubuntu, Debian and CentOS
DISTRO="$(lsb_release -si)"
CODENAME="$(lsb_release -sc)"
VERSION="$(lsb_release -sr | cut -d. -f1)"
OS="$DISTRO$VERSION"

# Begin Ubuntu
if [ "${DISTRO}" = "Ubuntu" ] ; then
apt-get -y install gnupg2
apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb -O percona-release_latest.deb
sudo dpkg -i percona-release_latest.deb
apt-get -y purge `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "`
apt-get -y install language-pack-en-base
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
apt-get -y install software-properties-common
add-apt-repository -y ppa:ondrej/php
apt-get -y autoremove
apt-get -y update
export DEBIAN_FRONTEND="noninteractive"
apt-get -y install apache2 php7.2 php7.2-zip php7.2-mysqlnd sqlite php7.2-gd php7.2-mbstring php7.2-xml php7.2-curl php7.2-sqlite wget nano zip unzip percona-server-server-5.7 ${EXTRA}
# Set MySQL Password
/sbin/service mysql start
service mysql start
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MySQLRoot}';"
# Begin Debian
elif [ "${DISTRO}" = "Debian" ] ; then
# Debian Repo
cat > /etc/apt/sources.list << eof
deb http://ftp.us.debian.org/debian/ ${CODENAME} main
deb-src http://ftp.us.debian.org/debian/ ${CODENAME} main

deb http://security.debian.org/ ${CODENAME}/updates main
deb-src http://security.debian.org/ ${CODENAME}/updates main

deb http://ftp.us.debian.org/debian/ ${CODENAME}-updates main
deb-src http://ftp.us.debian.org/debian/ ${CODENAME}-updates main
eof
apt-get -y update
apt-get -y install dirmngr apt-transport-https gnupg2
apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb -O percona-release_latest.deb
sudo dpkg -i percona-release_latest.deb
# Add PHP7 Repo
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt-get -y autoremove
apt-get -y update
apt-get -y purge `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "`
export DEBIAN_FRONTEND="noninteractive"
apt-get -y install apache2 php7.2 php7.2-mysqlnd php7.2-zip sqlite php7.2-gd php7.2-mbstring php7.2-xml php7.2-curl php7.2-sqlite wget nano zip unzip percona-server-server-5.7 ${EXTRA}
# Set MySQL Password
/sbin/service mysql start
service mysql start
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MySQLRoot}';"
# Begin CentOS
elif [ "${DISTRO}" = "CentOS" ] ; then
yum -y install http://percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm
yum -y install epel-release percona-release cronie
yum -y remove *mysql* *mariadb* php-*
mv /var/lib/mysql /var/lib/mysql-old
sed -i 's/DNS1=\(.*\)/\EDNS1=8.8.8.8/g' /etc/sysconfig/network-scripts/ifcfg-${IFACE}
sed -i 's/DNS2=\(.*\)/\EDNS2=8.8.4.4/g' /etc/sysconfig/network-scripts/ifcfg-${IFACE}
# Begin CentOS6
if [ "${OS}" = "CentOS6" ] ; then
yum -y install http://rpms.remirepo.net/enterprise/remi-release-6.rpm
echo 0 >/selinux/enforce
# Begin CentOS7
elif [ "${OS}" = "CentOS7" ] ; then
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install net-tools psmisc
echo 0 > /sys/fs/selinux/enforce
fi
# Begin CentOS6 and CentOS7 File Install
PHP_VERSION="7.2.11"
yum -y install yum-utils
yum-config-manager -y --enable remi-php72
yum -y --enablerepo=remi-php72 install php-${PHP_VERSION} php-cli-${PHP_VERSION} php-pdo-${PHP_VERSION} php-mysqlnd-${PHP_VERSION} php-mbstring-${PHP_VERSION} php-gd-${PHP_VERSION} php-xml-${PHP_VERSION}
yum -y install wget nano zip unzip httpd php-pecl-zip Percona-Server-client-57.x86_64 Percona-Server-devel-57.x86_64 Percona-Server-server-57.x86_64 Percona-Server-shared-57.x86_64  sqlite freetype mlocate ${EXTRA}
sed -i 's/SELINUX=enforcing/\ESELINUX=disabled/g' /etc/selinux/config
/sbin/chkconfig --level 2345 httpd on;
/sbin/service httpd start
service httpd start
/sbin/service mysql start
service mysql start
# Set MySQL Password
MYSQL_TMP_PWD="$(echo "$a" | cat  /var/log/mysqld.log | grep "A temporary password is generated for root@localhost: " | sed "s|^.*localhost: ||")"
mysql -uroot -p"${MYSQL_TMP_PWD}" --connect-expired-password -e "SET GLOBAL validate_password_policy=0;"
mysql -uroot -p"${MYSQL_TMP_PWD}" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MySQLRoot}';"
fi

# Save Generated MySQL Root Password.
cd /root/
cat > .my.cnf << eof
[client]
user="root"
password="${MySQLRoot}"
eof

# Multicraft Databases
mysql -e "CREATE DATABASE daemon;"
mysql -e "CREATE DATABASE panel;"
mysql -e "GRANT ALL ON daemon.* to daemon@localhost IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@localhost IDENTIFIED BY '${Panel}';"
mysql -e "GRANT ALL ON daemon.* to daemon@'%' IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@'%' IDENTIFIED BY '${Panel}';"

# Get Public IP
IP="$(curl -4 icanhazip.com)"
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
wget "https://github.com/JustOneMoreBlock/shell-scripts/blob/master/files/multicraft-jar-confs.zip?raw=true" -O multicraft-jar-confs.zip;
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
rm -fv api.php install.php

# Install Composer
wget https://getcomposer.org/installer -O composer-setup.php
php composer-setup.php --install-dir=/usr/bin

# Automated phpMyAdmin Installer
cd ${WebRoot}/
git clone --depth=1 --branch=STABLE git://github.com/phpmyadmin/phpmyadmin.git phpMyAdmin
mv ${WebRoot}/phpMyAdmin/config.sample.inc.php ${WebRoot}/phpMyAdmin/config.inc.php
sed -i "s/\$cfg\[.blowfish_secret.\]\s*=.*/\$cfg['blowfish_secret'] = '${BlowFish}';/" ${WebRoot}/phpMyAdmin/config.inc.php
cd ${WebRoot}/phpMyAdmin/
mkdir -p ${WebRoot}/phpMyAdmin/tmp/
chmod 1777 ${WebRoot}/phpMyAdmin/tmp/
php /usr/bin/composer.phar update --no-dev

# Modify php.ini Settings
sed -i 's/upload_max_filesize = \(.*\)/\Eupload_max_filesize = 100M/g' /etc/php.ini
sed -i 's/post_max_size = \(.*\)/\Epost_max_size = 100M/g' /etc/php.ini
sed -i 's/max_execution_time = \(.*\)/\Emax_execution_time = 300/g' /etc/php.ini
sed -i 's/max_input_time = \(.*\)/\Emax_input_time = 600/g' /etc/php.ini
sed -i 's/session.save_handler = \(.*\)/\Esession.save_handler = \/tmp/g' /etc/php.ini

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
sed -i "s/\#password =\(.*\)/\Epassword = ${DaemonPassword}/g" ${MulticraftConf}
sed -i 's/\#name =\(.*\)/\Ename = Server 1/g' ${MulticraftConf}
sed -i "s/#totalMemory =\(.*\)/\EtotalMemory = ${Memory}/g" ${MulticraftConf}
sed -i "s/\(.*\)baseDir =\(.*\)/\EbaseDir = \/home\/root\/multicraft\//g" ${MulticraftConf}
sed -i 's/\#multiuser =\(.*\)/\Emultiuser = true/g' ${MulticraftConf}
sed -i "s/\(.*\)forbiddenFiles\(.*\)/\#forbiddenFiles = /g" ${MulticraftConf}
sed -i "s/\ip = 127.0.0.1/\Eip = ${IP}/g" ${MulticraftConf}

# Multicraft Panel Config
cd /protected/config/
cat > config.php << eof
<?php
return array (
  'panel_db' => 'mysql:host=localhost;dbname=panel',
  'daemon_db' => 'mysql:host=localhost;dbname=daemon',
  'daemon_password' => '${DaemonPassword}',
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
  'show_repairtool' => 'superuser',
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
  'kill_button' => 'superuser',
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
sudo apt-get -y install openjdk-8-jre-headless
elif [ "${DISTRO}" = "Debian" ] ; then
sudo apt-get -y install openjdk-8-jre-headless
elif [ "${DISTRO}" = "CentOS" ] ; then
yum -y install java-1.8.0-openjdk
fi

java -version

# Restart Services
service apache2 stop
service apache2 start
/sbin/service httpd stop
/sbin/service httpd start

# Output Vars
cd /root/
cat > logins.conf << eof
# Stored Passwords
MySQL Root Password: ${MySQLRoot}
Multicraft Daemon: ${Daemon}
Multicraft Panel: ${Panel}

# Control Panel Link:
http://${IP}/multicraft/index.php
Username: admin
Password: ${AdminPassword}

# phpMyAdmin Link
http://${IP}/phpMyAdmin/index.php
Username: root
Password: ${MySQLRoot}
eof

cat /root/logins.conf

# Automatically Import MySQL Database Schema's, thus removing the web installer. :)
mysql -p${Panel} -u panel -D panel < /protected/data/panel/schema.mysql.sql
mysql -p${Daemon} -u daemon -D daemon < /protected/data/daemon/schema.mysql.sql

# Daemon MySQL Changes
mysql -p${Daemon} -u daemon -D daemon -e "INSERT INTO setting VALUES ('defaultServerIp', '1');"
mysql -p${Daemon} -u daemon -D daemon -e "INSERT INTO setting VALUES ('minecraftEula', 'auto');"

# Auto Start
cat > /opt/multicraft.sh << eof
#!/bin/bash
  
  /home/root/multicraft/bin/multicraft start
  /sbin/iptables -F
  /sbin/iptables -X

fi
eof

chmod +x /opt/multicraft.sh

echo "" | crontab -
crontab -l | { cat; echo "*/1 * * * * /opt/multicraft.sh"; } | crontab -
crontab -l

# Configure New Admin Password
SaltPassword="$(python -c "import crypt, getpass, pwd; \
             print crypt.crypt('${AdminPassword}', '\$6\$saltsalt\$')")"
mysql -p${Panel} -u panel -D panel -e "UPDATE user SET password='${SaltPassword}' WHERE name='admin';"
mysql -p${Daemon} -u daemon -D daemon -e "UPDATE ftp_user SET password='${SaltPassword}' WHERE name='admin';"
