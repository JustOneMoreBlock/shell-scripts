#!/bin/bash
# The MIT License (MIT)

# Copyright (c) 2018 Cory Gillenkirk

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

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

IP="$(curl -4 icanhazip.com)"

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
yum -y install https://mirror.webtatic.com/yum/el6/latest.rpm
yum -y update
yum -y install perl-Data-Dumper perl-Thread-Queue glibc-common glibc-utils make m4 gzip bzip2 bison gcc-c++ zip dos2unix httpd nano ca-certificates

cd /usr/local/src/
wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py
wget http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz -O autoconf-latest.tar.gz
wget http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz -O libtool-latest.tar.gz
wget http://ftp.gnu.org/gnu/automake/automake-1.15.1.tar.gz -O automake-latest.tar.gz

python get-pip.py
pip install getconf
tar -xf autoconf-latest.tar.gz
tar -xf libtool-latest.tar.gz
tar -xf automake-latest.tar.gz
cd /usr/local/src/autoconf*
./configure && make && make install
cd /usr/local/src/libtool*
./configure && make && make install
cd /usr/local/src/automake*
./configure && make && make install

mkdir -p /home/root/multicraft/jar/
cd /home/root/multicraft/jar/
wget https://raw.githubusercontent.com/pmmp/php-build-scripts/master/compile.sh -O compile.sh
dos2unix compile.sh
chmod +x compile.sh
sh compile.sh
cd bin
zip -r php7.zip php7
mv php7.zip /var/www/html/
/sbin/service httpd start
echo "http://${IP}/php7.zip"
