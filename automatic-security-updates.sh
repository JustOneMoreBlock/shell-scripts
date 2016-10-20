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

# Supported Versions: Ubuntu, Debian and CentOS 6 and 7.

# Update Resolve Servers
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# File Check
if [ -f /etc/network/interfaces ]; then
sed -i 's/dns-nameservers \(.*\)/\Edns-nameservers 8.8.8.8 8.8.4.4/g' /etc/network/interfaces
fi

# Install: lsb-release
apt-get -y install lsb-release
yum -y install redhat-lsb

# Detecting Distrubution of Linux
# Ubuntu, Debian and CentOS
DISTRO="$(lsb_release -si)"
VERSION="$(lsb_release -sr | cut -d. -f1)"
OS="$DISTRO$VERSION"

# Begin Ubuntu
if [ "${DISTRO}" = "Ubuntu" ] ; then
apt-get -y install cron-apt
# Begin Debian
elif [ "${DISTRO}" = "Debian" ] ; then
apt-get -y install cron-apt
# Begin CentOS
elif [ "${DISTRO}" = "CentOS" ] ; then
yum -y install yum-cron
# Begin CentOS6
if [ "${OS}" = "CentOS6" ] ; then
/etc/init.d/yum-cron start
chkconfig yum-cron on
# Begin CentOS7
elif [ "${OS}" = "CentOS7" ] ; then
/bin/systemctl status yum-cron.service
systemctl start yum-cron.service
fi
