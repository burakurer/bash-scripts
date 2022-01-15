#!/bin/bash

#######################################################
#                    burakurer.com                    #
#                                                     #
#     Version     : 1.1                               #
#     Last Update : 15/01/2022                        #
#     Website     : https://burakurer.com             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

if (($EUID != 0)); then
    echo "Lutfen dosyayi root olarak baslatin"
    exit
fi

update() {
    printf "\E[33mSistem guncellemeleri denetleniyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    yum update -y && yum upgrade -y && yum install wget nano perl -y
    printf "\E[32mSistem guncellemeleri tamamlandi\E[0m\n"
}

plesk() {
    printf "\E[33mPlesk kurulumu baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O – https://autoinstall.plesk.com/one-click-installer)
}

mariadbUpdate() {
    # https://support.plesk.com/hc/en-us/articles/213403429--How-to-upgrade-MySQL-5-5-to-5-6-5-7-or-MariaDB-5-5-to-10-x-on-Linux-
    
    printf "\E[33mMariaDB yukseltmesi baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    MYSQL_PWD=`cat /etc/psa/.psa.shadow` mysqldump -u admin --verbose --all-databases --routines --triggers > /tmp/all-databases.sql 2&> /dev/null

    if [ -f "/etc/yum.repos.d/MariaDB.repo" ] ; then
      mv /etc/yum.repos.d/MariaDB.repo /etc/yum.repos.d/mariadb.repo
    fi

    echo "MariaDB servisi durduruldu"
    systemctl stop mariadb


    echo "MySQL dizininin yedegi olusturuldu"
    cp -v -a /var/lib/mysql/ /var/lib/mysql_backup 2&> /dev/null

    rpm -e --nodeps "`rpm -q --whatprovides mysql-server`"

    echo "MariaDB yukseltiliyor"

    echo "#http://downloads.mariadb.org/mariadb/repositories/
    [mariadb]
    name = MariaDB
    baseurl = http://yum.mariadb.org/10.5/centos7-amd64
    gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
    gpgcheck=1" > /etc/yum.repos.d/mariadb.repo

    yum install MariaDB-client MariaDB-server MariaDB-compat MariaDB-shared -y

    systemctl restart mariadb

    MYSQL_PWD=`cat /etc/psa/.psa.shadow` mysql_upgrade -uadmin

    systemctl restart mariadb

    echo "Degisiklikler Plesk'e bildiriliyor.. (plesk sbin packagemng -sdf)"
    plesk sbin packagemng -sdf

    systemctl start mariadb
    systemctl enable mariadb
    printf "\E[32mMariaDB basariyla yukseltildi!\E[0m\n";
}

while :
do
    printf "\E[33mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
    echo -e "\n[1] Sistem guncellemelerini denetle\n[2] Plesk kur\n[3] MariaDB surumunu yukselt (10.X)"
    read r
    if [ $r == 1 ]; then
        update
    elif [ $r == 2 ]; then
        plesk
    elif [ $r == 3 ]; then
        mariadbUpdate
    else
        echo "Gecerli bir secenek girilmedi!"
        exit
    fi
done
