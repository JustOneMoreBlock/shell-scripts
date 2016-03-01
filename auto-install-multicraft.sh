# Update Resolve Servers
rm -fv /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sed -i 's/dns-nameservers \(.*\)/\Edns-nameservers 8.8.8.8 8.8.4.4/g' /etc/network/interfaces
cat /etc/resolv.conf

# Other Variables
IP=$(/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}') # Automatically gets the IP address and inputs it. :)

# Update and Install lsb-release
aptitude -y update
yum -y update
aptitude -y install lsb-release sudo
yum -y install redhat-lsb

#Password Generator with variables.
export MySQLRoot=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Daemon=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Panel=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export AdminPassword=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`

# might need to add check to verify they're installed. If not fail response.

#
#fail () {
#  mail -s "Cory something broke. You fix it." some@email.com
#}

# The detection the Distrubution of Linux.
# Eg. Ubuntu, Debian and CentOS.
# Using cat/sed magic is a mess and doesn't always work.
OS="$(lsb_release -si)"

if [ "${OS}" = "Ubuntu" ] ; then
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
  echo "deb http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee /etc/apt/sources.list.d/percona.list
  echo "deb-src http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee -a /etc/apt/sources.list.d/percona.list
  apt-get -y update
  export DEBIAN_FRONTEND="noninteractive"
  apt-get -y install apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip percona-server-server-5.6
  mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MySQLRoot}');"
  service mysql start
  service apache2 stop
  service apache2 start
elif [ "${OS}" = "Debian" ] ; then
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
  echo "deb http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee /etc/apt/sources.list.d/percona.list
  echo "deb-src http://repo.percona.com/apt "$(lsb_release -sc)" main" | sudo tee -a /etc/apt/sources.list.d/percona.list
  apt-get -y update
  export DEBIAN_FRONTEND="noninteractive"
  apt-get -y install apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip percona-server-server-5.6
  mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MySQLRoot}');"
  service mysql start
  service apache2 stop
  service apache2 start
elif [ "${OS}" = "CentOS" ] ; then
  rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
  rpm -Uvh http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
  yum -y remove *mysql* php-*
  mv /var/lib/mysql /var/lib/mysql-old
  yum -y install wget nano zip unzip httpd Percona-Server-client-56.x86_64 Percona-Server-devel-56.x86_64 Percona-Server-server-56.x86_64 Percona-Server-shared-56.x86_64 php56w php56w-pdo php56w-mysql php56w-mbstring sqlite php56w-gd freetype
  /sbin/chkconfig --level 2345 httpd on;
  /usr/bin/mysqladmin -u root password '${MySQLRoot}'
  /sbin/service mysql start
  /sbin/service httpd stop
  /sbin/service httpd start
fi

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
echo "MySQL Root Password: ${MySQLRoot}"
echo "Daemon Password: ${Daemon}"
echo "Panel Password: ${Panel}"

# Multicraft Download
mkdir /home/root/
cd /home/root/
wget http://multicraft.org/download/linux64 -O multicraft.tar.gz
tar -xf multicraft.tar.gz
cd multicraft
rm -rf jar api setup.sh eula.txt readme.txt
mv panel multicraft
mv multicraft.conf.dist multicraft.conf
mv multicraft /var/www/html/
mkdir jar
cd jar
wget "https://github.com/JustOneMoreBlock/shell-scripts/blob/master/files/multicraft-jar-confs.zip?raw=true" -O multicraft-jar-confs.zip;
unzip -o multicraft-jar-confs.zip
rm -fv multicraft-jar-confs.zip
cd /home/root/multicraft/

# Multicraft Config
# LOTS of sed magic here!
# Add memory checker
16GB="16384"
32GB="32768"
Memory="16"
MulticraftConf="/home/root/multicraft/multicraft.conf"
sed -i 's/user =\(.*\)/\Euser = root/g' ${MulticraftConf}
sed -i 's/\#id =\(.*\)/\Eid = 1/g' ${MulticraftConf}
sed -i 's/\#database = mysql/\Edatabase = mysql:host=127.0.0.1;dbname=daemon/g' ${MulticraftConf}
sed -i 's/\#dbUser =\(.*\)/\EdbUser = daemon/g' ${MulticraftConf}
sed -i "s/\#dbPassword =\(.*\)/\EdbPassword = ${Daemon}/g" ${MulticraftConf}
sed -i 's/\#name =\(.*\)/\Ename = Server 1/g' ${MulticraftConf}
sed -i "s/totalMemory =\(.*\)/\EtotalMemory = ${Memory}/g" ${MulticraftConf}
sed -i "s/\baseDir =\(.*\)/\EbaseDir = \/home\/root\/multicraft\/g" ${MulticraftConf}
sed -i 's/\#multiuser =\(.*\)/\Emultiuser = true/g' ${MulticraftConf}
sed -i 's/\forbiddenFiles =\(.*\)/\E#forbiddenFiles =/g' ${MulticraftConf}
sed -i "s/\ip = 127.0.0.1/\Eip = ${IP}/g" ${MulticraftConf}

# Multicraft Panel
cd /var/www/html/multicraft/
mv protected /
mv /protected/config/config.php.dist /protected/config/config.php
chmod 777 assets
chmod 777 /protected/runtime/
chmod 777 /protected/config/config.php
rm -fv api.php install.php
sed -i 's/dirname\(.*\)/\/\'\/protected\/yii\/yii.php';/g' index.php # Needs Testing

# phpMyAdmin
# Let's add phpMyAdmin Support!

# Permissions and Last Minute Settings
if [ "${OS}" = "Ubuntu" ] ; then
	sed -i 's/webUser =\(.*\)/\EwebUser = www-data:www-data/g' ${MulticraftConf}
	chown -R www-data:www-data /protected/
	chown -R www-data:www-data /var/www/html/multicraft/
elif [ "${OS}" = "Debian" ] ; then
	sed -i 's/webUser =\(.*\)/\EwebUser = www-data:www-data/g' ${MulticraftConf}
	chown -R www-data:www-data /protected/
	chown -R www-data:www-data /var/www/html/multicraft/
elif [ "${OS}" = "CentOS" ] ; then
	sed -i 's/webUser =\(.*\)/\EwebUser = nobody/g' ${MulticraftConf}
	chown -R nobody:nobody /protected/
	chown -R nobody:nobody /var/www/html/multicraft/
fi

# Multicraft Panel Config
# LOTS of sed magic here!
# Too tired to do this.

    # 'panel_db' => 'mysql:host=localhost;dbname=multicraft_panel',
    # 'panel_db_user' => 'root',
    # 'panel_db_pass' => '',

    # 'daemon_db' => 'mysql:host=localhost;dbname=multicraft_daemon',
    # 'daemon_db_user' => 'root',
    # 'daemon_db_pass' => 'testing',

    #  // Allow Users to Create a MySQL Database
    # 'user_mysql' => false,
    # // User MySQL DB information
    # 'user_mysql_host' => '',
    # 'user_mysql_user' => '',
    # 'user_mysql_pass' => '',
    # 'user_mysql_prefix' => '',
    # 'user_mysql_admin' => '',

# Automatically Import MySQL Database Schema's, thus removing the web installer. :)
mysql -p${Daemon} -u daemon daemon < /protected/data/daemon/schema.mysql.sql
mysql -p${Panel} -u panel panel < /protected/data/panel/schema.mysql.sql

# Configure New Admin Password
# Using: ${AdminPassword} and set in password.
# SaltPassword=$(`${AdminPassword}`)
# Need to read to figure out a solution for this.
mysql -p${panel} -u panel panel -e "UPDATE user SET password="${SaltPassword}" WHERE name="admin";"
echo "Updating: Admin Password ..."

# Daemon MySQL Changes
mysql -p${Daemon} -u daemon daemon -e "INSERT INTO setting VALUES('defaultServerIp', '1');"
echo "Set: Use Daemon IP ..."
mysql -p${Daemon} -u daemon daemon -e "INSERT INTO setting VALUES('minecraftEula', 'auto');"
echo "Set: Auto Enable EULA ..."

# Enable Auto Start on Reboot
echo "/home/root/multicraft/bin/multicraft start" >> /etc/rc.local

# Output Vars
echo "# Control Panel Link:"
echo "${IP}/multicraft/index.php"
echo "Username: admin"
echo "Password: ${AdminPassword}"
echo ""
echo "# phpMyAdmin Link"
echo "${IP}/phpMyAdmin/index.php"
echo "Username: root"
echo "Password: ${MySQLRoot}"
echo ""