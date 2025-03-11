#!/bin/bash

#######################################################
#                     burakurer.dev                   #
#                                                     #
#     Version     : 3.0.0                             #
#     Last Update : 11/03/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

if [[ $EUID -ne 0 ]]; then
    echo "Please run the script as root."
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
        echo "Operating system detection failed!"
        exit 1
    fi
}

checkSupportedOS() {
    getOSInfo
    case $OS in
        ubuntu|debian|centos|rocky|almalinux)
            ;;
        *)
            echo "This script is only compatible with Ubuntu, Debian, CentOS, Rocky Linux, and AlmaLinux!"
            exit 1
            ;;
    esac
}

checkSupportedOS

updateSystem() {
    clear
    echo -e "\E[31mChecking for system updates...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3

    case $OS in
        ubuntu|debian)
            apt update -y && apt upgrade -y && apt autoremove -y ;;
        centos|rocky|almalinux)
            yum update -y && yum upgrade -y && yum autoremove -y ;;
    esac

    clear
    echo -e "\E[32mSystem updates completed.\E[0m\n"
}

dateSync() {
    clear
    echo -e "\E[31mSyncing server time to Europe/Istanbul...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3
    ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
    hwclock --systohc
    timedatectl set-ntp on
    echo -e "\E[32mServer time synchronized.\E[0m\n"
}

installRecommendedPackages(){
    clear
    echo -e "\E[31mInstalling recommended packages...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3

    case $OS in
        ubuntu|debian)
            apt update -y && apt install -y wget curl nano htop snapd && snap install btop ;;
        centos|rocky|almalinux)
            yum update -y && yum install -y wget curl nano htop epel-release && yum repolist && yum install -y snapd && systemctl enable --now snapd.socket && ln -s /var/lib/snapd/snap /snap && snap install btop ;;
    esac

    clear
    echo -e "\E[32mRecommended packages installed.\E[0m\n"
}

installClamAV() {
    clear
    echo -e "\E[31mInstalling ClamAV...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3

    case $OS in
        ubuntu|debian)
            apt install -y clamav clamav-daemon && systemctl enable --now clamav-freshclam.service ;;
        centos|rocky|almalinux)
            yum install -y clamav clamav-update && freshclam && systemctl enable --now clamd@scan.service ;;
    esac

    echo -e "\E[32mClamAV installed and updated.\E[0m\n"
}

installPlesk() {
    clear
    echo -e "\E[31mStarting Plesk installation...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O - https://autoinstall.plesk.com/one-click-installer)
    echo -e "\E[32mPlesk installation completed.\E[0m\n"
}

installCaching() {
    clear
    echo -e "\e[31mInstalling Redis & Memcached...\e[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3

    case $OS in
        ubuntu|debian)
            apt update -y && apt install -y redis memcached
            systemctl enable --now redis memcached
            ;;
        centos)
            yum install -y epel-release
            yum install -y redis memcached
            systemctl enable --now redis memcached
            ;;
    esac

    echo -e "\e[32mRedis & Memcached installation completed.\e[0m\n"
}

createPleskLoginLink(){
    clear
    plesk login
}

removePleskBackups(){
    clear
    echo -e "\E[31mDeleting all Plesk backups...\E[0m\n(This operation is irreversible!)\n(Press Ctrl+C to cancel)\n"
    sleep 3
    rm -rf /var/lib/psa/dumps/*
    echo -e "\E[32mAll Plesk backups deleted.\E[0m\n"
}

fixPleskCurlError() {
    clear
    echo -e "\E[31m[PLESK] Fixing cURL error 77...\E[0m\n(Press Ctrl+C to cancel)\n"
    sleep 3
    systemctl restart plesk-php* && systemctl restart sw-engine
    echo -e "\E[32m[PLESK] cURL error 77 fixed.\E[0m\n"
}

while :; do
    echo -e "------------------------------------------\n\E[31mThis script was written by burakurer.dev\E[0m\n"
    echo -e "---General Operations---\n[1] Check for system updates\n[2] Synchronize server time (Europe/Istanbul)\n\n---Installations and Upgrades---\n[3] Install recommended packages (wget, curl, nano, htop, btop, epel-release, snapd)\n[4] Install ClamAV (Antivirus)\n[5] Install Plesk\n[6] Install Redis & Memcached\n\n---Plesk Operations---\n[7] Generate Plesk login link\n[8] Delete all Plesk backups\n\n---Error Fixes---\n[9] [PLESK] Fix cURL error 77\n"
    read -p "Enter an option (1-9): " r

    case $r in
        1) updateSystem ;;
        2) dateSync ;;

        3) installRecommendedPackages ;;
        4) installClamAV ;;
        5) installPlesk ;;
        6) installCaching ;;

        7) createPleskLoginLink ;;
        8) removePleskBackups ;;

        9) fixPleskCurlError ;;
        *) echo "Invalid option!"; exit ;;
    esac

done
