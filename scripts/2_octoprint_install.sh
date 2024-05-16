#!/bin/sh
if mount | grep "/dev/mmcblk0p1 on /overlay type ext4" > /dev/null; then

echo " "
echo " "
echo " "
echo "This script will download and install ALL packages from the internet"
echo " "
echo "   ######################################################"
echo "   ## Make sure you have a stable internet connection! ##"
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

opkg update
opkg install --force-overwrite gcc;
opkg install make unzip htop wget-ssl git-http kmod-video-uvc luci-app-mjpg-streamer v4l-utils mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www ffmpeg

opkg install python3 python3-pip python3-dev python3-psutil python3-yaml python3-netifaces
opkg install python3-pillow python3-tornado python3-markupsafe
pip install --upgrade setuptools
pip install --upgrade pip
pip install future regex sgmllib3k

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
git clone --depth 1 -b 1.10.1 https://github.com/OctoPrint/OctoPrint.git src
cd src
wget https://github.com/shivajiva101/OctoWrt/raw/23.05.3-150/octoprint/noargon2.patch
git apply noargon2.patch
echo "Starting pip install..."
pip install .
cd ~

echo " "
echo "   ###################"
echo "   ### Hostname/ip ###"
echo "   ###################"
echo " "

opkg install avahi-daemon-service-ssh avahi-daemon-service-http;

echo " "
echo "   ##################################"
echo "   ### Creating Octoprint service ###"
echo "   ##################################"
echo " "

rm -f /etc/init.d/octoprint
cat << "EOF" > /etc/init.d/octoprint
#!/bin/sh /etc/rc.common
# Copyright (C) 2009-2014 OpenWrt.org
# Put this inside /etc/init.d/

START=91
STOP=10
USE_PROCD=1


start_service() {
    procd_open_instance
    procd_set_param command octoprint serve --iknowwhatimdoing
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

else
echo "Run the first script before attempting to run this one!"
fi
