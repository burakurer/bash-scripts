#!/bin/bash

#######################################################
#                    burakurer.com                    #
#                                                     #
#     Version     : 1.2                               #
#     Last Update : 24/11/2022                        #
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
    yum update -y && yum upgrade -y
    printf "\E[32mSistem guncellemeleri tamamlandi\E[0m\n"
}

pleskInstall() {
    printf "\E[31mPlesk kurulumu baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O – https://autoinstall.plesk.com/one-click-installer)
}

aaPanelInstall() {
    printf "\E[31maaPanel kurulumu baslatiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh
}

mariadbUpgrade() {
    printf "\E[31mMySQL, MariaDB 10.5 sürümüne yükseltiliyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    wget https://support.plesk.com/hc/en-us/article_attachments/4584125667858/c7-mariadb-10.5-upgrade.sh && chmod +x c7-mariadb-10.5-upgrade.sh && ./c7-mariadb-10.5-upgrade.sh
}

dateSync() {
    printf "\E[31mSunucu tarihi senkronize ediliyor (Europe/Istanbul)\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
}

while :; do
    printf "\E[31mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
    echo -e "\n[1] Sistem guncellemelerini denetle\n[2] Plesk kur\n[3] aaPanel kur\n[4]MySQL'i MariaDB 10.5'e yukselt\n[5]Sunucu tarihini senkronize et (Europe/Istanbul)"
    read r
    if [ $r == 1 ]; then
        updateSystem
    elif [ $r == 2 ]; then
        pleskInstall
    elif [ $r == 3 ]; then
        aaPanelInstall
    elif [ $r == 4 ]; then
        mariadbUpgrade
    elif [ $r == 5 ]; then
        dateSync
    else
        echo "Gecerli bir secenek girilmedi!"
        exit
    fi
done
