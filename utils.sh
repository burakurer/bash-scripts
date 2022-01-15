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

while :
do
    printf "\E[31mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
    echo -e "\n[1] Sistem guncellemelerini denetle\n[2] Plesk kur\n[3] MariaDB surumunu yukselt (10.X)"
    read r
    if [ $r == 1 ]; then
        updateSystem
    elif [ $r == 2 ]; then
        pleskInstall
    else
        echo "Gecerli bir secenek girilmedi!"
        exit
    fi
done
