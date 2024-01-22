#!/bin/bash

#######################################################
#                    burakurer.com                    #
#                                                     #
#     Version     : 2.0.1                             #
#     Last Update : 22/01/2024                        #
#     Website     : https://burakurer.com             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

if [[ $EUID -ne 0 ]]; then
    echo "Lutfen dosyayi root olarak baslatin."
    exit 1
fi

getOSInfo() {
    if [[ -r /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [[ -r /etc/lsb-release ]]; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    else
        echo "Isletim sistemi tespit edilemedi!"
        exit 1
    fi
}

checkSupportedOS() {
    getOSInfo
    case $OS in
        ubuntu|debian|centos)
            ;;
        *)
            echo "Bu betik sadece Ubuntu, Debian ve CentOS ile uyumludur!"
            exit 1
            ;;
    esac
}

checkSupportedOS

# Genel Islemler
updateSystem() {
    clear
    echo -e "\E[31mSistem guncellemeleri denetleniyor.\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5

    case $OS in
        ubuntu|debian)
            apt update -y && apt upgrade -y ;;
        centos)
            yum update -y && yum upgrade -y ;;
    esac

    clear
    echo -e "\E[32mSistem guncellemeleri tamamlandi.\E[0m\n"
}

dateSync() {
    clear
    echo -e "\E[31mSunucu tarihi senkronize ediliyor. (Europe/Istanbul)\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
    hwclock --systohc
    echo -e "\E[32mSunucu tarihi senkronize edildi.\E[0m\n"
}

# Kurulumlar
recommendedPacketsInstall(){
    clear
    echo -e "\E[31mOnerilen paketler kuruluyor.\E[0m\n(Iptal için ctrl+c)\n"
    sleep 5

    case $OS in
        ubuntu|debian)
            apt update -y && apt install -y wget curl nano htop snapd && snap install btop ;;
        centos)
            yum update -y && yum install -y wget curl nano htop epel-release && yum repolist && yum install -y snapd && systemctl enable --now snapd.socket && ln -s /var/lib/snapd/snap /snap && snap install btop ;;
    esac

    clear
    echo -e "\E[32mOnerilen paketler kuruldu.\E[0m\n"
}

pleskInstall() {
    clear
    echo -e "\E[31mPlesk kurulumu baslatiliyor.\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O - https://autoinstall.plesk.com/one-click-installer)
    echo -e "\E[32mPlesk kurulumu tamamlandi.\E[0m\n"
}

aaPanelInstall() {
    clear
    echo -e "\E[31maaPanel kurulumu baslatiliyor.\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5

    case $OS in
        ubuntu)
            curl -o install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh aapanel ;;
        debian)
            curl -o install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel ;;
        centos)
            yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh aapanel ;;
    esac

    echo -e "\E[32maaPanel kurulumu tamamlandi.\E[0m\n"
}

cloudPanelInstall() {
    clear
    echo -e "\E[31mCloudPanel kurulumu baslatiliyor.\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5

    case $OS in
        ubuntu|debian)
            apt update && apt -y upgrade && apt -y install curl wget sudo
            curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
            echo "85762db0edc00ce19a2cd5496d1627903e6198ad850bbbdefb2ceaa46bd20cbd install.sh" | \
            sha256sum -c && sudo DB_ENGINE=MARIADB_10.11 bash install.sh
            echo -e "\E[32maaPanel kurulumu tamamlandi.\E[0m\n" ;;
        centos)
            echo "CloudPanel sadece Ubuntu ve Debian ve CentOS ile uyumludur!" ;;
    esac
}

mariadbUpgrade() {
    clear
    echo -e "\E[31mMySQL, MariaDB 10.5 surumune yukseltiliyor.\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    curl -O https://raw.githubusercontent.com/plesk/kb-scripts/master/c7-mariadb-10-5-upgrade/c7-mariadb-10-5-upgrade.sh && chmod +x c7-mariadb-10-5-upgrade.sh && ./c7-mariadb-10-5-upgrade.sh
    echo -e "\E[32 MySQL, MariaDB 10.5 surumune yukseltildi.\E[0m\n"
}

# Plesk
createPleskLoginLink(){
    clear
    plesk login
}
removePleskBackups(){
    clear
    echo -e "\E[31mSunucu uzerindeki tum Plesk yedekleri siliniyor. (Bu islemin geri donusu yoktur!)\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    rm -rf /var/lib/psa/dumps/*
    echo -e "\E[32mSunucu uzerindeki tum Plesk yedekleri silindi.\E[0m\n"
}

# Hata Cozumleri
error1(){
    clear
    echo -e "\E[31m[PLESK] cURL error 77 hatasi cozumleniyor\E[0m\n(Iptal icin ctrl+c)\n"
    sleep 5
    systemctl restart plesk-php* && systemctl restart sw-engine
    echo -e "\E[32m[PLESK] cURL error 77 hatasi cozumlendi.\E[0m\n"
}

while :; do
    echo -e "   ------------------------------------------\n\E[31mBu bash scripti burakurer.com tarafindan yazilmistir\E[0m\n"
    echo -e "---Genel Islemler---\n[1] Sistem guncellemelerini denetle\n[2] Sunucu tarihini senkronize et (Europe/Istanbul)\n\n---Kurulumlar ve Yukseltmeler---\n[3] Onerilen paketleri kur (EPEL, wget..)\n[4] Plesk kur\n[5] aaPanel kur\n[6] CloudPanel kur\n[7] MySQL'i MariaDB 10.5'e yukselt\n\n---Hata Cozumleri---\n[8] [PLESK] cURL error 77\n\n---Plesk Islemleri---\n[9] Plesk giris linki olustur\n[10] Sunucu uzerindeki tum Plesk yedeklerini sil\n"
    read -p "Secenek girin (1-10): " r

    case $r in
        1) updateSystem ;;
        2) dateSync ;;

        3) recommendedPacketsInstall ;;
        4) pleskInstall ;;
        5) aaPanelInstall ;;
        6) cloudPanelInstall ;;
        7) mariadbUpgrade ;;

        8) error1 ;;

        9) createPleskLoginLink ;;
        10) removePleskBackups ;;
        *) echo "Gecerli bir secenek girilmedi!"; exit ;;
    esac
done