#!/bin/sh

echo " "
echo "   ########################################"
echo "   ## Did you execute 1_format.sh first? ##"
echo "   ########################################"
echo " "
read -p "Press [ENTER] if YES ...or [ctrl+c] to exit"


echo " "
echo "This script will download and install all packages from the internet"
echo " "
echo "   #####################################"
echo "   ## Make sure extroot is enabled... ##"
echo "   #####################################"
echo " "
read -p "Press [ENTER] to check if extroot is enabled ...or [ctrl+c] to exit"

df -h;

echo " "
echo "   ############################################"
echo "   ## Is /dev/mmcblk0p1 mounted on /overlay? ##"
echo "   ############################################"
echo " "
read -p "Press [ENTER] if YES... or [ctrl+c] to exit"

echo " "
echo "   ######################################################"
echo "   ## Make sure you have a stable Internet connection! ##"
echo "   ######################################################"
echo " "
read -p "Press [ENTER] to Continue ...or [ctrl+c] to exit"

echo " "
echo "   #################"
echo "   ###   SWAP    ###"
echo "   #################"
echo " "

echo "Creating swap file"
dd if=/dev/zero of=/overlay/swap.page bs=1M count=512;
echo "Enabling swap file"
mkswap /overlay/swap.page;
swapon /overlay/swap.page;
mount -o remount,size=256M /tmp;

echo "Updating rc.local for swap"
rm /etc/rc.local;
cat << "EOF" > /etc/rc.local
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.
###activate the swap file on the SD card
swapon /overlay/swap.page
###expand /tmp space
mount -o remount,size=256M /tmp
exit 0
EOF

echo " "
echo "   ###############################"
echo "   ### Installing dependencies ###"
echo "   ###############################"
echo " "

echo "Updating distfeeds.conf"
rm /etc/opkg/distfeeds.conf;
wget https://github.com/shivajiva101/OctoWrt/raw/23.05.0-137/openwrt/distfeeds.conf -P /etc/opkg

opkg update
opkg install gcc make unzip htop wget-ssl git-http v4l-utils mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www ffmpeg

opkg install python3 python3-pip python3-dev python3-psutil python3-pillow python3-tornado
pip install --upgrade pip
pip install --upgrade setuptools
pip install virtualenv
virtualenv venv

echo " "
echo "   ############################"
echo "   ### Installing Octoprint ###"
echo "   ############################"
echo " "
echo " This is going to take a while... "
echo " No seriously, it will look like it's frozen"
echo " for extended periods of time but it will"
echo " eventually complete!"
echo " "

echo "Cloning source..."
git clone -b 1.9.3 --single-branch https://github.com/shivajiva101/OctoPrint.git src
cd src
echo "Starting pip install..."
../venv/bin/pip install .
cd ~

echo " "
echo "   ##################################"
echo "   ### Creating Octoprint service ###"
echo "   ##################################"
echo " "

cat << "EOF" > /etc/init.d/octoprint
#!/bin/sh /etc/rc.common
# Copyright (C) 2009-2014 OpenWrt.org
# Put this inside /etc/init.d/

START=91
STOP=10
USE_PROCD=1


start_service() {
    procd_open_instance
    procd_set_param command /root/venv/bin/octoprint serve --iknowwhatimdoing
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF

chmod +x /etc/init.d/octoprint
/etc/init.d/octoprint enable

echo " "
echo "   ##################################"
echo "   ### Reboot and wait a while... ###"
echo "   ##################################"
echo " "
read -p "Press [ENTER] to reboot...or [ctrl+c] to exit"

reboot
