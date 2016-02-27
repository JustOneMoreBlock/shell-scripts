# Update and Install lsb-release
aptitude -y update
yum -y update
aptitude -y install lsb-release
yum -y install redhat-lsb

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
  DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server-5.6 apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip
elif [ "${OS}" = "Debian" ] ; then
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
  wget https://repo.percona.com/apt/percona-release_0.1-3.$(lsb_release -sc)_all.deb
  dpkg -i percona-release_0.1-3.$(lsb_release -sc)_all.deb
  apt-get -y update
  DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server-5.6 apache2 php5 php5-mysql sqlite php5-gd php5-sqlite wget nano zip unzip
elif [ "${OS}" = "CentOS" ] ; then
  rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
  rpm -Uvh http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
  yum -y remove *mysql* php-*
  mv /var/lib/mysql /var/lib/mysql-old
  yum -y install wget nano zip unzip httpd Percona-Server-client-56.x86_64 Percona-Server-devel-56.x86_64 Percona-Server-server-56.x86_64 Percona-Server-shared-56.x86_64 php56w php56w-pdo php56w-mysql php56w-mbstring sqlite php56w-gd freetype
  /sbin/chkconfig --level 2345 httpd on;
fi

#Password Generator with variables.
export MySQLRoot=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Daemon=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export Panel=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`
export AdminPassword=`cat /dev/urandom | tr -dc A-Za-z0-9 | dd bs=25 count=1 2>/dev/null`

#MySQL Setup
service mysql start
# This doesn't work.
# It's because of DEBIAN_FRONTEND=noninteractive in the apt-get install.
# The password is empty or random and don't know it. We cannot set it on install.
/usr/bin/mysqladmin -u root password '${MySQLRoot}'
# This doesn't work and should be removed.
# mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MySQLRoot}');"
# mysql -e "exit;"

# Once 
cd /root/
cat > .my.cnf << eof
[client]
user="root"
pass="${MySQLRoot}"
eof
echo -e "[Configured] MySQL Root Password: ${MySQLRoot}"
cat /root/.my.cnf

# Multicraft Databases
mysql -e "CREATE DATABASE daemon;"
mysql -e "CREATE DATABASE panel;"
mysql -e "GRANT ALL ON daemon.* to daemon@localhost IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@localhost IDENTIFIED BY '${Panel}';"
mysql -e "GRANT ALL ON daemon.* to daemon@'%' IDENTIFIED BY '${Daemon}';"
mysql -e "GRANT ALL ON panel.* to panel@'%' IDENTIFIED BY '${Panel}';"
echo -e "[Created Daemon] Password: ${Daemon}"
echo -e "[Created Panel] Password: ${Panel}"

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
wget jarfiles;

# Multicraft Config
# LOTS of sed magic here!

# Multicraft Panel
cd /var/www/html/multicraft/
mv protected /
mv /protected/config/config.php.dist /protected/config/config.php
chmod 777 assets
chmod 777 /protected/runtime/
chmod 777 /protected/config/config.php
rm -fv api.php install.php
# sed index.php file

# Permissions
#Debian/Ubuntu
chown -R www-data:www-data /protected/
chown -R www-data:www-data /var/www/html/multicraft/
#CentOS
chown -R nobody:nobody /protected/
chown -R nobody:nobody /var/www/html/multicraft/

# Multicraft Panel Config
# LOTS of sed magic here!

#Restart Services
/sbin/service apache2 stop
/sbin/service apache2 start
/sbin/service httpd stop
/sbin/service httpd start
echo -e "[Restart] Services ..."

# Configure New Admin Password
# Using: ${AdminPassword} and set in password.
# SaltPassword=$(`${AdminPassword}`)
mysql -e "UPDATE user SET password="${SaltPassword}" WHERE name="admin";"
echo -e "[Upating] Admin Password ..."

