# Various Shell Scripts
These are shell scripits I've been writing to make things easier. :)

MIT License

# Auto Install Multicraft
(Supported Versions: Ubuntu 14-16, Debian 7/8 and CentOS 6/7)
```
yum -y install wget; apt-get -y install wget; wget https://raw.githubusercontent.com/JustOneMoreBlock/shell-scripts/master/auto-install-multicraft.sh -O auto-install-multicraft.sh; chmod +x auto-install-multicraft.sh; sh auto-install-multicraft.sh
```

Built-In:
- Uses Google Resolve Servers
- Password Generator: MySQL Root Password, Multicraft Daemon, Multicraft Panel, Multicraft Admin Password, and Blowfish Secret.
- Installs: Apache, PHP 5.6 (gd, xml, curl, sqlite), Percona MySQL, curl, git, wget, and nano.
- Automatically Configures MySQL Root Password and stores it in /root/.my.cnf
- Automatically Configures usernames/passwords for daemon and panel for the use of Multicraft and stores these passwords in /root/logins.cnf
- Automatically downloads the latest Multicraft.
- Automatically downloads jars and it's configuration files.
- Automatically sets up Multicraft Security.
- Automatically configures multicraft.conf.
- Automatically configures config.php for Multicraft.
- Automated Java Installer (Author: Mike G. aka metalcated and partially forked from n0ts (https://github.com/metalcated/)
- Automated phpMyAdmin Installer with password generated blowfish setup.
- Automated php.ini detector (Used to create a symlink to /etc/php.ini)
- Automated memory detector (Used to configure your multicraft.conf max memory.
- Automated admin password for Multicraft.

Auto Install cron for Automatic Security Updates: (Supported Versions: Ubuntu, Debian and CentOS 6 and 7)
```
yum -y install wget; sudo apt-get -y install wget; wget; wget https://raw.githubusercontent.com/JustOneMoreBlock/shell-scripts/master/automatic-security-updates.sh -O automatic-security-updates.sh; chmod +x automatic-security-updates.sh; sh automatic-security-updates.sh
```
