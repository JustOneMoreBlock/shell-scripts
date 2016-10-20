# Various Shell Scripts
These are shell scripits I've been writing to make things easier. :)

MIT License

Auto Install Multicraft and Libs: (Supported Versions: Ubuntu, Debian and CentOS 6 and 7)
```
yum -y install wget; sudo apt-get -y install wget; wget; wget https://raw.githubusercontent.com/JustOneMoreBlock/shell-scripts/master/auto-install-multicraft.sh -O auto-install-multicraft.sh; chmod +x auto-install-multicraft.sh; sh auto-install-multicraft.sh
```

Auto Install cron for Automatic Security Updates: (Supported Versions: Ubuntu, Debian and CentOS 6 and 7)
```
yum -y install wget; sudo apt-get -y install wget; wget; wget https://raw.githubusercontent.com/JustOneMoreBlock/shell-scripts/master/automatic-security-updates.sh -O automatic-security-updates.sh; chmod +x automatic-security-updates.sh; sh automatic-security-updates.sh
```

auto-install-multicraft.sh
- Use Google Resolve Servers
- Password Generator
- Installs: Apache, PHP, MySQL, Curl, Git, etc...
- Automatically Configures root password and stores it in /root/.my.cnf
- Automatically Configures usernames/password for daemon and panel for the use of Multicraft and stores these passwords in /root/mc.cnf
- Automatically downloads the latest Multicraft.
- Automatically downloads jars and it's configuration files.
- Automatically sets up Multicraft Security.
- Automatically configures multicraft.conf.
- Automatically configures config.php for Multicraft.
- Automated Java Installer
- Automated phpMyAdmin Installer with password generated blowfish setup.

# Few Additional Things
- Automated php.ini detector (Used to create a symlink to /etc/php.ini)
- Automated memory detector (Used to configure your multicraft.conf max memory.

Automated Java Installer for RPMs uses: install_java.sh file which was created by:
- Author: Mike G. aka metalcated and partially forked from n0ts (https://github.com/metalcated/)
