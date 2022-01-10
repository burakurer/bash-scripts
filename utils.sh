#!/bin/bash

if (($EUID != 0)); then
    echo "Lutfen dosyayi root olarak baslatin"
    exit
fi

update() {
    printf "\E[31mSistem guncellemeleri denetleniyor\E[0m\n"
    sleep 5
    yum upgrade -y || apt-get upgrade -y
    yum update -y || apt-get update -y
    printf "\E[31mSistem guncellemeleri tamamlandi\E[0m\n"
}

plesk() {
    printf "\E[31mPlesk kurulumu baslatiliyor\E[0m\n"
    sleep 5
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O – https://autoinstall.plesk.com/one-click-installer)
}

printf "\E[31mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
echo -e "\n[1]Sistem guncellemelerini denetle\n[2]Plesk kur"
read r

if [ $r == 1 ]; then
    update
elif [ $r == 2 ]; then
    plesk
else
    echo "Gecerli bir secenek girilmedi!"
    exit
fi
