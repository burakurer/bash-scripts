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

updateSystem() {
    printf "\E[31mSistem guncellemeleri denetleniyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    yum update -y && yum upgrade -y && yum install wget nano perl -y
    printf "\E[32mSistem guncellemeleri tamamlandi\E[0m\n"
}

pleskInstall() {
    printf "\E[31mPlesk kurulumu baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O – https://autoinstall.plesk.com/one-click-installer)
}

mariadbUpdate() {
    # https://support.plesk.com/hc/en-us/articles/213403429--How-to-upgrade-MySQL-5-5-to-5-6-5-7-or-MariaDB-5-5-to-10-x-on-Linux-
    
    printf "\E[31mMariaDB yukseltmesi baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    
    wget https://plesk.zendesk.com/hc/article_attachments/360022419980/mariadb-10.5-upgrade.sh && chmod +x mariadb-10.5-upgrade.sh
    ./mariadb-10.5-upgrade.sh
    printf "\E[32mMariaDB basariyla yukseltildi!\E[0m\n";
}

while :
do
    printf "\E[31mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
    echo -e "\n[1] Sistem guncellemelerini denetle\n[2] Plesk kur\n[3] MariaDB surumunu yukselt (10.X)"
    read r
    if [ $r == 1 ]; then
        updateSystem
    elif [ $r == 2 ]; then
        pleskInstall
    elif [ $r == 3 ]; then
        mariadbUpdate
    else
        echo "Gecerli bir secenek girilmedi!"
        exit
    fi
done
